import { combineReducers, configureStore } from '@reduxjs/toolkit'
import { scraperApi, compareApi } from '../services'
import { cartSlice } from '../components/articleCart'
import { articleSlice, searchSlice } from '../components'
import type { ToolkitStore } from '@reduxjs/toolkit/dist/configureStore'
import { persistReducer, FLUSH, REHYDRATE, PAUSE, PERSIST, PURGE, REGISTER } from 'redux-persist'
import storage from 'redux-persist/lib/storage'

const cartPersistConfig = {
    key: 'cart',
    storage,
}

const searchPersistConfig = {
    key: 'search',
    storage,
}

const reducers = {
    [scraperApi.reducerPath]: scraperApi.reducer,
    [compareApi.reducerPath]: compareApi.reducer,
    cart: persistReducer(cartPersistConfig, cartSlice.reducer),
    search: persistReducer(searchPersistConfig, searchSlice.reducer),
    compare: articleSlice.reducer,
}
const rootReducer = combineReducers(reducers)

export function setupStore(preloadedState?: Partial<RootState>): ToolkitStore {
    return configureStore({
        reducer: rootReducer,
        preloadedState,
        middleware: getDefaultMiddleware => {
            return getDefaultMiddleware({
                serializableCheck: {
                    ignoredActions: [FLUSH, REHYDRATE, PAUSE, PERSIST, PURGE, REGISTER],
                },
            })
                .concat(scraperApi.middleware)
                .concat(compareApi.middleware)
        },
    })
}

export type RootState = ReturnType<typeof rootReducer>
export type AppStore = ReturnType<typeof setupStore>
export type AppDispatch = AppStore['dispatch']
