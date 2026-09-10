/**
 * @jest-environment jsdom
 */
import 'whatwg-fetch'
import '@testing-library/jest-dom'
import userEvent from '@testing-library/user-event'
import { cleanup, screen, waitFor } from '@testing-library/react'
import { SearchArticles } from '../../../src/components'
import { renderWithProviders, buildSingleRouterWrapper } from '../../../src/utils'
import nock from 'nock'
import i18n from '../../../src/i18n'
import { setupNetworkError, setupSuccess, testTopic } from './mocks/searchArticlesMock'
import { RouterProvider, createMemoryRouter } from 'react-router-dom'

afterEach(() => {
    cleanup()
})

describe('SearchArticles component parts', () => {
    test('Displays all the information', () => {
        renderWithProviders(buildSingleRouterWrapper(<SearchArticles />))

        expect(screen.getByTestId('contrast-logo')).toBeInTheDocument()
        expect(screen.getByPlaceholderText(i18n.t('search-a-topic'))).toBeInTheDocument()
    })

    test('Input updates its value when user types', async () => {
        renderWithProviders(buildSingleRouterWrapper(<SearchArticles />))

        const inputValue = 'test input'
        const input = screen.getByLabelText('search-input')

        await userEvent.type(input, inputValue)

        await waitFor(() => {
            expect(input).toHaveValue(inputValue)
        })
    })

    test('Deleting input value shows empty topic message', async () => {
        renderWithProviders(buildSingleRouterWrapper(<SearchArticles />))

        const inputValue = 'test input'
        const input = screen.getByLabelText('search-input')

        await userEvent.type(input, inputValue)

        await waitFor(() => {
            expect(input).toHaveValue(inputValue)
        })

        await userEvent.clear(input)

        await waitFor(() => {
            expect(input).toHaveValue('')
        })

        expect(screen.getByText(i18n.t('empty-topic-error'))).toBeInTheDocument()
    })
})

describe('Submitting errors', () => {
    beforeEach(setupNetworkError)
    afterEach(nock.cleanAll)

    test('Shows connection error if the search fails', async () => {
        renderWithProviders(buildSingleRouterWrapper(<SearchArticles />))

        const inputValue = testTopic
        const input = screen.getByLabelText('search-input')

        await userEvent.type(input, inputValue)

        await waitFor(() => {
            expect(input).toHaveValue(inputValue)
        })

        // User clicks the input and submits
        await userEvent.click(input)
        await userEvent.keyboard('[Enter]')

        await waitFor(() => {
            expect(screen.getByText(i18n.t('fetch-error'))).toBeInTheDocument()
        })
    })

    test('Shows empty topic error when search topic is empty', async () => {
        renderWithProviders(buildSingleRouterWrapper(<SearchArticles />))

        const inputValue = '   '
        const input = screen.getByLabelText('search-input')

        await userEvent.type(input, inputValue)

        await waitFor(() => {
            expect(input).toHaveValue(inputValue)
        })

        // User clicks the input and submits
        await userEvent.click(input)
        await userEvent.keyboard('[Enter]')

        await waitFor(() => {
            expect(screen.getByText(i18n.t('empty-topic-error'))).toBeInTheDocument()
        })
    })
})

describe('Successful search', () => {
    beforeEach(() => {
        if (!nock.isActive()) {
            nock.activate()
        }
        setupSuccess()
    })
    afterAll(nock.cleanAll)

    test('Navigates to new route when the search is successful', async () => {
        const routes = [
            {
                path: `/search_results/${testTopic}`,
                element: <div>testDiv</div>,
            },
            {
                path: '/',
                element: <SearchArticles />,
            },
        ]

        const router = createMemoryRouter(routes, {
            initialEntries: [`/search_results/${testTopic}`, '/'],
            initialIndex: 1,
        })

        renderWithProviders(<RouterProvider router={router} />)

        const inputValue = testTopic
        const input = screen.getByLabelText('search-input')

        await userEvent.type(input, inputValue)

        await waitFor(() => {
            expect(input).toHaveValue(inputValue)
        })

        // User clicks the input and submits
        await userEvent.click(input)
        await userEvent.keyboard('[Enter]')

        await waitFor(() => {
            expect(screen.queryByText('testDiv')).toBeInTheDocument()
        })
    })
})

describe('Loading search results', () => {
    test('Displays spinner', async () => {
        renderWithProviders(buildSingleRouterWrapper(<SearchArticles />))

        const inputValue = testTopic
        const input = screen.getByLabelText('search-input')

        await userEvent.type(input, inputValue)

        await waitFor(() => {
            expect(input).toHaveValue(inputValue)
        })

        // User clicks the input and submits
        await userEvent.click(input)
        await userEvent.keyboard('[Enter]')

        await waitFor(() => {
            expect(screen.getByTestId('search-spinner')).toBeInTheDocument()
        })
    })
})
