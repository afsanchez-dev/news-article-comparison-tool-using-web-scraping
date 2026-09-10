import { Flex, Button, HStack, useColorMode, Box } from '@chakra-ui/react'
import { SunIcon, MoonIcon } from '@chakra-ui/icons'
import { Logo, SideBarDisplayer } from '.'
import type { FC } from 'react'
import { CartDisplayer } from '../articleCart'

/**
 * Props for NavBar
 */
export interface NavBarProps {
    /**
     * A boolean for controlling toggle sidebar button displaying
     */
    hasSideBarButton: boolean
    /**
     * A boolean for controlling logo displaying
     */
    hasLogo: boolean
    /**
     * A boolean for controlling selected articles button displaying
     */
    hasSelectedArticlesButton: boolean
}
/**
 * NavBar is a custom React component for the navigation bar of the app
 * @param {NavBarProps}
 * @returns {JSX.Element}
 */
export const NavBar: FC<NavBarProps> = ({
    hasSideBarButton,
    hasLogo,
    hasSelectedArticlesButton,
}) => {
    const { colorMode, toggleColorMode } = useColorMode()

    return (
        <>
            <Flex
                as='nav'
                p='0.5rem'
                alignItems='center'
                justify='space-between'
                position='fixed'
                w='100%'
                backdropFilter='saturate(180%)'
                zIndex='1'
                backgroundColor={colorMode === 'light' ? 'white' : 'gray.800'}
                boxShadow={colorMode === 'light' ? 'base' : 'xl'}
            >
                {hasSideBarButton ? <SideBarDisplayer /> : null}

                <Box position='absolute' left='50%' transform='translateX(-50%)'>
                    {hasLogo ? <Logo fontSize={{ base: '2rem' }} /> : null}
                </Box>

                <HStack ml='0.5rem'>
                    {hasSelectedArticlesButton ? <CartDisplayer /> : null}
                    <Button
                        data-testid='theme-mode-button'
                        onClick={toggleColorMode}
                        border={colorMode === 'light' ? '1px' : 'hidden'}
                        borderColor='gray.300'
                    >
                        {colorMode === 'light' ? (
                            <SunIcon data-testid='sun-icon' />
                        ) : (
                            <MoonIcon data-testid='moon-icon' />
                        )}
                    </Button>
                </HStack>
            </Flex>
        </>
    )
}
