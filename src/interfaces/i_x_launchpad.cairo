// SPDX-License-Identifier: MIT
use starknet::ContractAddress;

#[derive(Drop, Serde)]
pub enum NFTType {
    ERC721,
    ERC1155,
}

#[starknet::interface]
pub trait IXLaunchpad<TContractState> {
    fn set_x_launchpad_l1_address(ref self: TContractState, l1_address: felt252);
    fn launch_x_nft(
        ref self: TContractState,
        name: ByteArray,
        symbol: ByteArray,
        uri: ByteArray,
        nft_type: NFTType,
    ) -> ContractAddress;
}
