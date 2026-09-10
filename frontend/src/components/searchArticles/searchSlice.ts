import { type PayloadAction, createSlice } from '@reduxjs/toolkit'
import { type RootState } from '../../app/store'

interface searchSliceState {
    lastTopic: string
}

const initialState: searchSliceState = {
    lastTopic: '',
}

export const searchSlice = createSlice({
    name: 'search',
    initialState,
    reducers: {
        updateTopic(state, action: PayloadAction<string>) {
            state.lastTopic = action.payload
        },
        clearTopic(state) {
            state.lastTopic = ''
        },
    },
})

export const selectTopic = (state: RootState): string => state.search.lastTopic
export const { updateTopic, clearTopic } = searchSlice.actions
