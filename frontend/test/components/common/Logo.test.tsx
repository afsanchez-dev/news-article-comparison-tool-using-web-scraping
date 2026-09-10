/**
 * @jest-environment jsdom
 */
import 'whatwg-fetch'
import { screen } from '@testing-library/react'
import { renderWithProviders, buildSingleRouterWrapper } from '../../../src/utils'
import { Logo } from '../../../src/components'
import '@testing-library/jest-dom'

describe('Logo component', () => {
    test('Shows the expected information', () => {
        renderWithProviders(buildSingleRouterWrapper(<Logo fontSize={{ base: '2rem' }} />))

        expect(screen.getByText(/CON/)).toBeInTheDocument()
        expect(screen.getByText(/TRAST/)).toBeInTheDocument()
    })
})
