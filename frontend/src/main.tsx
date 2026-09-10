import React from 'react'
import ReactDOM from 'react-dom/client'
import { createBrowserRouter, RouterProvider } from 'react-router-dom'
import { Provider } from 'react-redux'
import { ChakraProvider, ColorModeScript } from '@chakra-ui/react'
import { setupStore } from './app/store'
import { I18nextProvider } from 'react-i18next'
import i18n from './i18n'
import theme from './theme.ts'
import { ErrorPage } from './pages'
import { CompareArticles, SearchArticles, SearchResults } from './components'
import { Root, Results, Compare } from './layouts'
import { PersistGate } from 'redux-persist/integration/react'
import { persistStore } from 'redux-persist'

const store = setupStore()
const persistor = persistStore(store)

const router = createBrowserRouter([
    {
        path: '/',
        element: <Root />,
        errorElement: <ErrorPage />,
        children: [
            {
                path: '/',
                element: <SearchArticles />,
            },
        ],
    },
    {
        path: '/search_results/:topic',
        element: <Results />,
        errorElement: <ErrorPage />,
        children: [
            {
                path: '/search_results/:topic',
                element: <SearchResults />,
            },
        ],
    },
    {
        path: '/compare_articles/',
        element: <Compare />,
        errorElement: <ErrorPage />,
        children: [
            {
                path: '/compare_articles/',
                element: <CompareArticles />,
            },
        ],
    },
])

// eslint-disable-next-line @typescript-eslint/no-non-null-assertion
ReactDOM.createRoot(document.getElementById('root')!).render(
    <React.StrictMode>
        <Provider store={store}>
            <PersistGate persistor={persistor}>
                <ChakraProvider>
                    <ColorModeScript initialColorMode={theme.config.initialColorMode} />
                    <I18nextProvider i18n={i18n}>
                        <RouterProvider router={router} />
                    </I18nextProvider>
                </ChakraProvider>
            </PersistGate>
        </Provider>
    </React.StrictMode>
)
