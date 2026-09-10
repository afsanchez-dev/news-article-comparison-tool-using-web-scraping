/**
 * @jest-environment jsdom
 */
import 'whatwg-fetch'
import '@testing-library/jest-dom'
import { cleanup, fireEvent, screen } from '@testing-library/react'
import { ScraperErrorAlert } from '../../../src/components'
import { renderWithProviders, buildSingleRouterWrapper } from '../../../src/utils'
import i18n from '../../../src/i18n'

const errorMessage = 'This is a test error'
const testErrors = [
    {
        scraper: 'el-pais',
        results: {
            error: errorMessage,
        },
    },
]

afterEach(cleanup)

describe('ScraperErrorAlert component', () => {
    test('Displays all the information', () => {
        renderWithProviders(
            buildSingleRouterWrapper(<ScraperErrorAlert scraperErrors={testErrors} />)
        )
        const pattern = new RegExp(`${i18n.t('no-results-scraper-error')}`)

        expect(screen.getByText(pattern)).toBeInTheDocument()
        expect(screen.getByText(/El País/)).toBeInTheDocument()
    })

    test('Closing button works', () => {
        renderWithProviders(
            buildSingleRouterWrapper(<ScraperErrorAlert scraperErrors={testErrors} />)
        )

        const closingButton = screen.getByTestId('scraper-alert-close-button')

        // The alert is displayed
        expect(screen.getByText(/El País/)).toBeInTheDocument()

        // We click the closing button
        fireEvent.click(closingButton)

        // The alert is closed
        expect(screen.queryByText(/El País/)).toBeNull()
    })
})
