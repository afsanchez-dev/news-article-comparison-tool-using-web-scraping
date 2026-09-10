/**
 * @jest-environment jsdom
 */
import 'whatwg-fetch'
import '@testing-library/jest-dom'
import { cleanup, screen, fireEvent } from '@testing-library/react'
import { ErrorPanel } from '../../../src/components'
import { renderWithProviders, buildSingleRouterWrapper } from '../../../src/utils'
import i18n from '../../../src/i18n'
import { RouterProvider, createMemoryRouter } from 'react-router-dom'

const testErrorMessage = 'This is a test error'
const mockRefecth = jest.fn()

afterEach(cleanup)

describe('ErrorPanel component', () => {
    test('Displays all the information', () => {
        renderWithProviders(
            buildSingleRouterWrapper(
                <ErrorPanel errorMessage={testErrorMessage} refetchFunction={mockRefecth} />
            )
        )

        expect(screen.getByText(testErrorMessage)).toBeInTheDocument()
        expect(screen.getByText(i18n.t('error-notification'))).toBeInTheDocument()
        expect(screen.getByText(i18n.t('try-again'))).toBeInTheDocument()
        expect(screen.getByText(i18n.t('search-another-topic'))).toBeInTheDocument()
    })

    test('Refetch button works', () => {
        renderWithProviders(
            buildSingleRouterWrapper(
                <ErrorPanel errorMessage={testErrorMessage} refetchFunction={mockRefecth} />
            )
        )

        const refetchButton = screen.getByTestId('refetch-button')

        fireEvent.click(refetchButton)

        expect(mockRefecth).toHaveBeenCalled()
    })

    test('Search another topic button works', () => {
        const routes = [
            {
                path: '/',
                element: <div>testDiv</div>,
            },
            {
                path: '/errorPanel',
                element: (
                    <ErrorPanel errorMessage={testErrorMessage} refetchFunction={mockRefecth} />
                ),
            },
        ]

        const router = createMemoryRouter(routes, {
            initialEntries: ['/', '/errorPanel'],
            initialIndex: 1,
        })

        renderWithProviders(<RouterProvider router={router} />)

        const searchAnotherButton = screen.getByTestId('search-another-topic-button')

        // We are in the error panel
        expect(screen.getByText(testErrorMessage)).toBeInTheDocument()

        // We click the button
        fireEvent.click(searchAnotherButton)

        // We are in the test div page
        expect(screen.getByText('testDiv')).toBeInTheDocument()
    })
})
