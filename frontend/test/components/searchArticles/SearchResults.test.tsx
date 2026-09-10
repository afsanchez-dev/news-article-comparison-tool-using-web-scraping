/**
 * @jest-environment jsdom
 */
import 'whatwg-fetch'
import '@testing-library/jest-dom'
import userEvent from '@testing-library/user-event'
import { cleanup, screen, waitFor } from '@testing-library/react'
import { SearchResults } from '../../../src/components'
import { renderWithProviders } from '../../../src/utils'
import nock from 'nock'
import i18n from '../../../src/i18n'
import {
    setupDelayed,
    setupNetworkError,
    setupSuccess,
    setupTotalError,
    testTopic,
} from './mocks/searchArticlesMock'
import { RouterProvider, createMemoryRouter, useNavigate } from 'react-router-dom'
import { type FC, useEffect } from 'react'

const RedirectionComponent: FC = () => {
    const navigate = useNavigate()
    useEffect(() => {
        navigate(`/search_results/${testTopic}`)
    }, [navigate])

    return <div>Sample text</div>
}
const routes = [
    {
        path: '/search_results/:topic',
        element: <SearchResults />,
    },
    {
        path: '/',
        element: <div>testDiv</div>,
    },
    {
        path: '/redirection',
        element: <RedirectionComponent />,
    },
]

const router = createMemoryRouter(routes, {
    initialEntries: [`/search_results/${testTopic}`, '/', '/redirection'],
    initialIndex: 2,
})

afterEach(() => {
    cleanup()
})

describe('SearchResults component parts', () => {
    beforeEach(() => {
        setupSuccess()
    })
    afterEach(nock.cleanAll)

    test('Displays all the information', async () => {
        renderWithProviders(<RouterProvider router={router} />)

        const pattern = new RegExp(`${i18n.t('results-for')}`)
        await waitFor(() => {
            expect(screen.getByText(pattern)).toBeInTheDocument()
            expect(screen.getByText(/Test title0/)).toBeInTheDocument()
            expect(screen.getByText(i18n.t('show-more'))).toBeInTheDocument()
        })
    })

    test('Show more should fail', async () => {
        renderWithProviders(<RouterProvider router={router} />)

        const pattern = new RegExp(`${i18n.t('results-for')}`)
        await waitFor(async () => {
            expect(screen.getByText(pattern)).toBeInTheDocument()
            const showMoreButton = screen.getByText(i18n.t('show-more'))
            expect(showMoreButton).toBeInTheDocument()

            await userEvent.click(showMoreButton)
            expect(screen.getByText(/Test title2/)).toBeInTheDocument()
        })
    })
})

describe('Shows error panel when results had errors', () => {
    beforeEach(setupTotalError)
    afterEach(nock.cleanAll)
    test('Shows error panel', async () => {
        renderWithProviders(<RouterProvider router={router} />)
        const alertPattern = new RegExp(`${i18n.t('empty-result-error')}`)
        await waitFor(() => {
            expect(screen.queryAllByText(alertPattern)[0]).toBeInTheDocument()
        })
    })
})

describe('Shows error panel when there are network errors', () => {
    beforeEach(setupNetworkError)
    afterEach(nock.cleanAll)

    test('Shows error panel', async () => {
        renderWithProviders(<RouterProvider router={router} />)

        const alertPattern = new RegExp(`${i18n.t('error-notification')}`)
        await waitFor(() => {
            expect(screen.queryAllByText(alertPattern)[0]).toBeInTheDocument()
        })
    })
})

describe('Shows spinner while loading when response is delayed', () => {
    beforeEach(setupDelayed)
    afterEach(nock.cleanAll)

    test('Shows spinner and eventually shows results', async () => {
        renderWithProviders(<RouterProvider router={router} />)

        await waitFor(() => {
            expect(screen.getByTestId('search-results-spinner')).toBeInTheDocument()
        })

        await waitFor(
            () => {
                expect(screen.getByText(/Test title0/)).toBeInTheDocument()
            },
            { timeout: 500 }
        )
    })
})
