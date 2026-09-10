import { Text } from '@chakra-ui/react'
import type { FC } from 'react'

/**
 * Footer is a custom React component that displays information about the author of this project
 * @returns {JSX.Element}
 */
export const Footer: FC = () => {
    return (
        <Text
            m='2rem'
            textColor='gray.400'
            fontSize={{ base: '0.70rem', md: '0.75rem', lg: '1rem' }}
        >
            Adolfo Fanjul Sánchez - Universidade da Coruña
        </Text>
    )
}
