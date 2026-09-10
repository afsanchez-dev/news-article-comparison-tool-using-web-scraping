import { Grid, GridItem, useBreakpoint } from '@chakra-ui/react'
import type { FC } from 'react'
import { Outlet } from 'react-router-dom'
import { NavBar, Footer, BackButton } from '../components'
import { useAppSelector } from '../app/hooks'

/**
 * Compare is a custom React component for creating the article comparing layout of the app
 * @returns {JSX.Element}
 */
export const Compare: FC = () => {
    const breakpoint = useBreakpoint('sm')
    const hasLogo = !(breakpoint === 'base' || breakpoint === 'sm' || breakpoint === 'md')
    const lastTopic = useAppSelector(state => state.search.lastTopic)

    return (
        <>
            <Grid templateRows='8vh 8vh 80vh 10vh'>
                {/* NavBar */}
                <GridItem>
                    <NavBar
                        hasLogo={hasLogo}
                        hasSideBarButton={true}
                        hasSelectedArticlesButton={false}
                    />
                </GridItem>

                <GridItem ml='4rem'>
                    <BackButton route={`/search_results/${lastTopic}`} />
                </GridItem>

                {/* Main Content */}
                <GridItem>
                    <Outlet />
                </GridItem>

                {/* Footer */}
                <GridItem textAlign='center'>
                    <Footer />
                </GridItem>
            </Grid>
        </>
    )
}
