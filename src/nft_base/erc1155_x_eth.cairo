// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts for Cairo ^0.19.0

#[starknet::contract]
pub mod ERC1155xETH {
    use starknet::{
        ClassHash, ContractAddress, storage::{StoragePointerReadAccess, StoragePointerWriteAccess},
        syscalls::send_message_to_l1_syscall,
    };
    use openzeppelin::{
        access::accesscontrol::{AccessControlComponent, DEFAULT_ADMIN_ROLE},
        introspection::src5::SRC5Component,
        security::{pausable::PausableComponent, initializable::InitializableComponent},
        token::{erc1155::ERC1155Component, common::erc2981::{DefaultConfig, ERC2981Component}},
        upgrades::{interface::IUpgradeable, UpgradeableComponent},
    };

    component!(path: ERC1155Component, storage: erc1155, event: ERC1155Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: PausableComponent, storage: pausable, event: PausableEvent);
    component!(path: InitializableComponent, storage: initializable, event: InitializableEvent);
    component!(path: AccessControlComponent, storage: accesscontrol, event: AccessControlEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);
    component!(path: ERC2981Component, storage: erc2981, event: ERC2981Event);

    // External
    #[abi(embed_v0)]
    impl ERC1155MixinImpl = ERC1155Component::ERC1155MixinImpl<ContractState>;
    #[abi(embed_v0)]
    impl PausableImpl = PausableComponent::PausableImpl<ContractState>;
    #[abi(embed_v0)]
    impl InitializableImpl =
        InitializableComponent::InitializableImpl<ContractState>;
    #[abi(embed_v0)]
    impl AccessControlImpl =
        AccessControlComponent::AccessControlImpl<ContractState>;
    #[abi(embed_v0)]
    impl AccessControlCamelImpl =
        AccessControlComponent::AccessControlCamelImpl<ContractState>;
    #[abi(embed_v0)]
    impl ERC2981Impl = ERC2981Component::ERC2981Impl<ContractState>;
    #[abi(embed_v0)]
    impl ERC2981InfoImpl = ERC2981Component::ERC2981InfoImpl<ContractState>;
    #[abi(embed_v0)]
    impl ERC2981AdminAccessControlImpl =
        ERC2981Component::ERC2981AdminAccessControlImpl<ContractState>;

    // Internal
    impl ERC1155InternalImpl = ERC1155Component::InternalImpl<ContractState>;
    impl PausableInternalImpl = PausableComponent::InternalImpl<ContractState>;
    impl InitializableInternalImpl = InitializableComponent::InternalImpl<ContractState>;
    impl AccessControlInternalImpl = AccessControlComponent::InternalImpl<ContractState>;
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;
    impl ERC2981InternalImpl = ERC2981Component::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc1155: ERC1155Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        pausable: PausableComponent::Storage,
        #[substorage(v0)]
        initializable: InitializableComponent::Storage,
        #[substorage(v0)]
        accesscontrol: AccessControlComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        #[substorage(v0)]
        erc2981: ERC2981Component::Storage,
        name: ByteArray,
        symbol: ByteArray,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC1155Event: ERC1155Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        PausableEvent: PausableComponent::Event,
        #[flat]
        InitializableEvent: InitializableComponent::Event,
        #[flat]
        AccessControlEvent: AccessControlComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        #[flat]
        ERC2981Event: ERC2981Component::Event,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState, default_admin: ContractAddress, royalty_admin: ContractAddress,
    ) {
        self.accesscontrol.initializer();
        self.erc2981.initializer(royalty_admin, 750);

        self.accesscontrol._grant_role(DEFAULT_ADMIN_ROLE, default_admin);
        self.accesscontrol._grant_role(DEFAULT_ADMIN_ROLE, royalty_admin);
        self.accesscontrol._grant_role(ERC2981Component::ROYALTY_ADMIN_ROLE, royalty_admin);
    }

    impl ERC1155HooksImpl of ERC1155Component::ERC1155HooksTrait<ContractState> {
        fn before_update(
            ref self: ERC1155Component::ComponentState<ContractState>,
            from: ContractAddress,
            to: ContractAddress,
            token_ids: Span<u256>,
            values: Span<u256>,
        ) {
            let contract_state = self.get_contract();
            contract_state.pausable.assert_not_paused();
        }
    }

    #[generate_trait]
    #[abi(per_item)]
    impl ExternalImpl of ExternalTrait {
        #[external(v0)]
        fn initialize(ref self: ContractState, name: ByteArray, symbol: ByteArray, uri: ByteArray) {
            self.accesscontrol.assert_only_role(DEFAULT_ADMIN_ROLE);
            self.erc1155.initializer(uri);
            self.name.write(name);
            self.symbol.write(symbol);
            self.initializable.initialize();
            self.accesscontrol.initializer();
        }

        #[external(v0)]
        fn name(self: @ContractState) -> ByteArray {
            self.name.read()
        }

        #[external(v0)]
        fn symbol(self: @ContractState) -> ByteArray {
            self.symbol.read()
        }

        #[external(v0)]
        fn pause(ref self: ContractState) {
            self.accesscontrol.assert_only_role(DEFAULT_ADMIN_ROLE);
            self.pausable.pause();
        }

        #[external(v0)]
        fn unpause(ref self: ContractState) {
            self.accesscontrol.assert_only_role(DEFAULT_ADMIN_ROLE);
            self.pausable.unpause();
        }

        #[external(v0)]
        fn mint(
            ref self: ContractState,
            account: ContractAddress,
            token_id: u256,
            value: u256,
            data: Span<felt252>,
        ) {
            self.accesscontrol.assert_only_role(DEFAULT_ADMIN_ROLE);
            self.erc1155.mint_with_acceptance_check(account, token_id, value, data);
        }

        #[external(v0)]
        fn batch_mint(
            ref self: ContractState,
            account: ContractAddress,
            token_ids: Span<u256>,
            values: Span<u256>,
            data: Span<felt252>,
        ) {
            self.accesscontrol.assert_only_role(DEFAULT_ADMIN_ROLE);
            self.erc1155.batch_mint_with_acceptance_check(account, token_ids, values, data);
        }

        #[external(v0)]
        fn batchMint(
            ref self: ContractState,
            account: ContractAddress,
            tokenIds: Span<u256>,
            values: Span<u256>,
            data: Span<felt252>,
        ) {
            self.batch_mint(account, tokenIds, values, data);
        }

        #[external(v0)]
        fn set_base_uri(ref self: ContractState, base_uri: ByteArray) {
            self.accesscontrol.assert_only_role(DEFAULT_ADMIN_ROLE);
            self.erc1155._set_base_uri(base_uri);
        }

        #[external(v0)]
        fn setBaseUri(ref self: ContractState, baseUri: ByteArray) {
            self.set_base_uri(baseUri);
        }
    }

    //
    // Upgradeable
    //

    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.accesscontrol.assert_only_role(DEFAULT_ADMIN_ROLE);
            self.upgradeable.upgrade(new_class_hash);
        }
    }
}
