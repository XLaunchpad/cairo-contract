// SPDX-License-Identifier: MIT
use starknet::{ClassHash, ContractAddress};

#[starknet::interface]
pub trait IERC1155xETH<TContractState> {
    fn initialize(ref self: TContractState, name: ByteArray, symbol: ByteArray, uri: ByteArray);
    fn name(self: @TContractState) -> ByteArray;
    fn symbol(self: @TContractState) -> ByteArray;
    fn pause(ref self: TContractState);
    fn unpause(ref self: TContractState);
    fn mint(
        ref self: TContractState,
        account: ContractAddress,
        token_id: u256,
        value: u256,
        data: Span<felt252>,
    );
    fn batch_mint(
        ref self: TContractState,
        account: ContractAddress,
        token_ids: Span<u256>,
        values: Span<u256>,
        data: Span<felt252>,
    );
    fn set_base_uri(ref self: TContractState, base_uri: ByteArray);
    fn upgrade(ref self: TContractState, new_class_hash: ClassHash);
}
