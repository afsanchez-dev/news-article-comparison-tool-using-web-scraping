/**
 * @jest-environment jsdom
 */
import 'whatwg-fetch'
import '@testing-library/jest-dom'
import { cleanup, screen } from '@testing-library/react'
import { CompareArticles } from '../../../src/components'
import { renderWithProviders } from '../../../src/utils'
import { setupSuccess } from './mocks/compareArticlesMock'
import nock from 'nock'
import i18n from '../../../src/i18n'
import { RouterProvider, createMemoryRouter } from 'react-router-dom'
import { searchArticles } from '../searchArticles/mocks/searchArticlesMock'
import { type ArticleSummary } from '../../../src/types'
import userEvent from '@testing-library/user-event'

const routes = [
    {
        path: '/compare_articles',
        element: <CompareArticles />,
    },
    {
        path: '/',
        element: <div>testDiv</div>,
    },
]

const router = createMemoryRouter(routes, {
    initialEntries: ['/compare_articles/', '/'],
    initialIndex: 0,
})

const getMockArticleSummaries = (): ArticleSummary[] => {
    const responses = searchArticles(2)

    return responses.reduce<ArticleSummary[]>(
        (acc, response) => [...acc, response.results as unknown as ArticleSummary],
        []
    )
}

const stateMock = {
    cart: {
        cartItems: getMockArticleSummaries(),
        _persist: {
            version: 1,
            rehydrated: false,
        },
    },
}

afterEach(() => {
    cleanup()
})

describe('CompareArticles component parts', () => {
    beforeEach(() => {
        setupSuccess()
    })
    afterEach(nock.cleanAll)

    test('Displays comparison info', async () => {
        renderWithProviders(<RouterProvider router={router} />, {
            preloadedState: stateMock,
        })

        const selectArticlePattern = new RegExp(`${i18n.t('select-article')}`)

        const comparisonSelectButtons = screen.queryAllByText(selectArticlePattern)

        expect(comparisonSelectButtons.length).toBeGreaterThan(0)
        await userEvent.click(comparisonSelectButtons[0])

        const switchPattern = new RegExp(`${i18n.t('switch-articles')}`)
        const switchButton = screen.queryByText(switchPattern)
        expect(switchButton).toBeInTheDocument()
        if (switchButton != null) await userEvent.click(switchButton)
    })
})
