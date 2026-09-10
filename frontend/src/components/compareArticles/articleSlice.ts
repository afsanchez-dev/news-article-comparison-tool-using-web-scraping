import { type PayloadAction, createSlice } from '@reduxjs/toolkit'
import { type ArticleSummary } from '../../types'
import { type RootState } from '../../app/store'

export interface compareSelection {
    articleSummary: ArticleSummary
    index: number
}

interface articleSliceState {
    compareSelections: compareSelection[]
    currSelection: compareSelection | null
    currSelectorIndex: number
    layout: number
}

const initialState: articleSliceState = {
    compareSelections: [],
    currSelection: null,
    currSelectorIndex: 0,
    layout: 2,
}

export const articleSlice = createSlice({
    name: 'compare',
    initialState,
    reducers: {
        addToCompare(state, action: PayloadAction<ArticleSummary>) {
            const index = state.currSelectorIndex
            const selection = {
                articleSummary: action.payload,
                index,
            }
            const removedIndex = state.compareSelections.filter(
                selection => selection.index !== index
            )
            state.compareSelections = [...removedIndex, selection]
            state.currSelection = selection
        },
        removeFromCompare(state, action: PayloadAction<number>) {
            state.compareSelections = state.compareSelections.filter(
                compareSelection => compareSelection.index !== action.payload
            )

            if (state.compareSelections.length === 0) state.currSelectorIndex = 0
        },
        setCurrSelector(state, action: PayloadAction<number>) {
            state.currSelectorIndex = action.payload
        },
        clearCompare(state) {
            state.compareSelections = []
            state.currSelectorIndex = 0
        },
        updateLayout(state, action: PayloadAction<number>) {
            state.layout = action.payload
        },
    },
})

export const selectCompareArticles = (state: RootState): compareSelection[] => {
    return state.compare.compareSelections
}

export const selectCurrSelection = (state: RootState): compareSelection | null =>
    state.compare.currSelection

export const { addToCompare, removeFromCompare, setCurrSelector, clearCompare, updateLayout } =
    articleSlice.actions
