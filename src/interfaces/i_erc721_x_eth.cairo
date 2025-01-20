// SPDX-License-Identifier: MIT
use starknet::{ClassHash, ContractAddress};

#[starknet::interface]
pub trait IERC721xETH<TContractState> {
    fn initialize(ref self: TContractState, name: ByteArray, symbol: ByteArray, uri: ByteArray);
    fn pause(ref self: TContractState);
    fn unpause(ref self: TContractState);
    fn safe_mint(
        ref self: TContractState, recipient: ContractAddress, token_id: u256, data: Span<felt252>,
    );
    fn upgrade(ref self: TContractState, new_class_hash: ClassHash);
}
