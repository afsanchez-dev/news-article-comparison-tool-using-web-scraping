import { Grid, GridItem, Spacer } from '@chakra-ui/react'
import type { FC } from 'react'
import { Outlet } from 'react-router-dom'
import { NavBar, Footer } from '../components'

/**
 * Root is a custom React component for creating the root layout of the app
 * @returns {JSX.Element}
 */
export const Root: FC = () => {
    return (
        <>
            <Grid templateRows='8vh 25vh 30vh 25vh 8vh'>
                {/* NavBar */}
                <GridItem>
                    <NavBar
                        hasLogo={false}
                        hasSideBarButton={true}
                        hasSelectedArticlesButton={true}
                    />
                </GridItem>

                <GridItem>
                    <Spacer />
                </GridItem>

                {/* Main Content */}
                <GridItem>
                    <Outlet />
                </GridItem>

                <GridItem>
                    <Spacer />
                </GridItem>

                {/* Footer */}
                <GridItem textAlign='center'>
                    <Footer />
                </GridItem>
            </Grid>
        </>
    )
}
