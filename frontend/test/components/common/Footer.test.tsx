/**
 * @jest-environment jsdom
 */
import 'whatwg-fetch'
import { screen } from '@testing-library/react'
import { renderWithProviders } from '../../../src/utils'
import { Footer } from '../../../src/components'
import '@testing-library/jest-dom'

describe('Footer component', () => {
    test('Shows the expected information', () => {
        renderWithProviders(<Footer />)

        expect(
            screen.getByText(/Adolfo Fanjul Sánchez - Universidade Da Coruña/)
        ).toBeInTheDocument()
    })
})
