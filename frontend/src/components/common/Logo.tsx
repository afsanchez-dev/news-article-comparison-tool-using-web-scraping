import type { FC } from 'react'
import {
    Box,
    Heading,
    type HeadingProps,
    type ResponsiveObject,
    Text,
    Link as ChakraLink,
    useColorMode,
} from '@chakra-ui/react'
import { Link as ReactRouterLink } from 'react-router-dom'

/**
 * Props for Logo
 */
export interface LogoProps extends HeadingProps {
    /**
     * A responsive object from the ChakraUI library that enables the fontsize
     * to change based on screen size
     * @example {base: '1rem', sm: '1.25rem', md: '1.5rem'}
     */
    fontSize: ResponsiveObject<string | number>
}

/**
 * Logo is a custom React component created to represent the app logo
 * @param {LogoProps}
 * @returns {JSX.Element}
 */
export const Logo: FC<LogoProps> = ({ fontSize }) => {
    const { colorMode } = useColorMode()

    return (
        <ChakraLink as={ReactRouterLink} to='/' _hover={{ textDecoration: 'none' }}>
            <Box as='header' data-testid='contrast-logo'>
                <Heading
                    as='h1'
                    fontSize={fontSize}
                    fontWeight='bold'
                    color={colorMode === 'light' ? 'black' : 'white'}
                >
                    CON
                    <Text
                        as='span'
                        bg={colorMode === 'light' ? 'black' : 'white'}
                        color={colorMode !== 'light' ? 'blackAlpha.900' : 'white'}
                    >
                        TRAST
                    </Text>
                </Heading>
            </Box>
        </ChakraLink>
    )
}
