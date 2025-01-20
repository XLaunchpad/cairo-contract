// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts for Cairo ^0.19.0

#[starknet::contract]
pub mod XLaunchpad {
    use starknet::storage::{
        Map, StoragePathEntry, StorageMapReadAccess, StorageMapWriteAccess,
        StoragePointerReadAccess, StoragePointerWriteAccess,
    };
    use OwnableComponent::InternalTrait;
    use starknet::{
        ClassHash, ContractAddress, EthAddress, SyscallResultTrait,
        syscalls::{deploy_syscall, send_message_to_l1_syscall}, get_caller_address,
        get_contract_address,
    };
    use openzeppelin::{
        access::ownable::OwnableComponent,
        upgrades::{interface::IUpgradeable, UpgradeableComponent},
    };
    use x_launchpad::interfaces::{
        i_erc721_x_eth::{IERC721xETHDispatcher, IERC721xETHDispatcherTrait},
        i_erc1155_x_eth::{IERC1155xETHDispatcher, IERC1155xETHDispatcherTrait},
    };
    use alexandria_bytes::{Bytes, BytesTrait};

    const ERC721BASE_CLASS_HASH: felt252 =
        0x009d187a50c941594675a1a5927ff5a363e7885f4fbab20415c171349dc65502;
    const ERC1155BASE_CLASS_HASH: felt252 =
        0x068fb95e3b3d0e5cafdd49c7b6db48ef1f45bc0d8c8c7be25a27a48f86ffc8e3;
    const STORE_ADDRESSES_MESSAGE: felt252 = 0;

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    // External
    #[abi(embed_v0)]
    impl OwnableTwoStepMixinImpl =
        OwnableComponent::OwnableTwoStepMixinImpl<ContractState>;

    // Internal
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    #[derive(Drop, Serde)]
    enum NFTType {
        ERC721,
        ERC1155,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
    }

    #[derive(Drop, starknet::Event)]
    struct NFTLaunchedOnSN {
        #[key]
        nft_address: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct NFTLaunchedFromETH {
        #[key]
        l1_nft_address: EthAddress,
        #[key]
        l2_nft_address: ContractAddress,
    }

    #[storage]
    struct Storage {
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        x_launchpad_l1_address: felt252,
        l1_l2_address_map: Map<EthAddress, ContractAddress>,
        l2_l1_address_map: Map<ContractAddress, EthAddress>,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        self.ownable.initializer(owner);
    }

    #[generate_trait]
    #[abi(per_item)]
    impl ExternalImpl of ExternalTrait {
        #[external(v0)]
        fn set_x_launchpad_l1_address(ref self: ContractState, l1_address: felt252) {
            self.ownable.assert_only_owner();
            self.x_launchpad_l1_address.write(l1_address);
        }

        #[external(v0)]
        fn launch_x_nft(
            ref self: ContractState,
            name: ByteArray,
            symbol: ByteArray,
            uri: ByteArray,
            nft_type: NFTType,
        ) -> ContractAddress {
            let caller = get_caller_address();
            let address_this = get_contract_address();
            let nft_contract_address = match nft_type {
                NFTType::ERC721 => {
                    let deploy_erc721_base = deploy_syscall(
                        ERC721BASE_CLASS_HASH.try_into().unwrap(),
                        0,
                        array![address_this.into(), caller.into()].span(),
                        true,
                    );

                    let (erc721_base_address, _) = deploy_erc721_base.unwrap_syscall();
                    IERC721xETHDispatcher { contract_address: erc721_base_address }
                        .initialize(name, symbol, uri);
                    erc721_base_address
                },
                NFTType::ERC1155 => {
                    let deploy_erc1155_base = deploy_syscall(
                        ERC1155BASE_CLASS_HASH.try_into().unwrap(),
                        0,
                        array![address_this.into(), caller.into()].span(),
                        true,
                    );

                    let (erc1155_base_address, _) = deploy_erc1155_base.unwrap_syscall();
                    IERC1155xETHDispatcher { contract_address: erc1155_base_address }
                        .initialize(name, symbol, uri);
                    erc1155_base_address
                },
            };
            nft_contract_address
        }
    }

    #[l1_handler]
    fn launch_x_nft_from_eth(
        ref self: ContractState,
        from_address: felt252,
        name: Bytes,
        symbol: Bytes,
        uri_1: Bytes,
        uri_2: Bytes,
        nft_type: NFTType,
        l1_address: EthAddress,
    ) {
        assert(
            from_address == self.x_launchpad_l1_address.read(), 'Caller not launchpad L1 address',
        );
        let mut uri: Bytes = uri_1.clone();
        uri.concat(@uri_2);
        let l2_address = self.launch_x_nft(name.into(), symbol.into(), uri.into(), nft_type);
        self.l1_l2_address_map.entry(l1_address).write(l2_address);
        self.l2_l1_address_map.entry(l2_address).write(l1_address);

        // Send the message.
        let mut message_payload = ArrayTrait::new();
        STORE_ADDRESSES_MESSAGE.serialize(ref message_payload);
        l1_address.serialize(ref message_payload);
        l2_address.serialize(ref message_payload);
        let result = send_message_to_l1_syscall(
            self.x_launchpad_l1_address.read(), message_payload.span(),
        );
        assert(result.is_ok(), 'MESSAGE_SEND_FAIILED');
    }

    #[l1_handler]
    fn store_l1_nft_address(
        ref self: ContractState,
        from_address: felt252,
        l1_address: EthAddress,
        l2_address: ContractAddress,
    ) {
        assert(
            from_address == self.x_launchpad_l1_address.read(), 'Caller not launchpad L1 address',
        );
        self.l1_l2_address_map.entry(l1_address).write(l2_address);
        self.l2_l1_address_map.entry(l2_address).write(l1_address);
    }

    //
    // Upgradeable Impl
    //

    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.upgradeable.upgrade(new_class_hash);
        }
    }
}
