import { type PayloadAction, createSlice } from '@reduxjs/toolkit'
import { type ArticleSummary } from '../../types'
import { type RootState } from '../../app/store'

interface cartSliceState {
    cartItems: ArticleSummary[]
}
const initialState: cartSliceState = {
    cartItems: [] as ArticleSummary[],
}

export const cartSlice = createSlice({
    name: 'cart',
    initialState,
    reducers: {
        addToCart(state, action: PayloadAction<ArticleSummary>) {
            state.cartItems = [...state.cartItems, action.payload]
        },
        removeFromCart(state, action: PayloadAction<ArticleSummary>) {
            state.cartItems = state.cartItems.filter(artSumm => artSumm.url !== action.payload.url)
        },
        clearCart(state) {
            state.cartItems = []
        },
    },
})

export const selectCartItems = (state: RootState): ArticleSummary[] => state.cart.cartItems
export const { addToCart, removeFromCart, clearCart } = cartSlice.actions
