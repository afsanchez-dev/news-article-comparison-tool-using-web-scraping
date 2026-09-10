import { RepeatIcon, SearchIcon } from '@chakra-ui/icons'
import {
    Alert,
    AlertDescription,
    AlertIcon,
    AlertTitle,
    Button,
    HStack,
    VStack,
    useColorMode,
} from '@chakra-ui/react'
import type { FC } from 'react'
import { useTranslation } from 'react-i18next'
import { useNavigate } from 'react-router-dom'

/**
 * Props for ErrorPanel
 */
export interface ErrorPanelProps {
    /**
     * An error message
     */
    errorMessage: string
    /**
     * A refetch function
     */
    refetchFunction: () => void
}

/**
 * ErrorPanel is a custom React component for displaying search errors and refetching results
 * @param {ErrorPanelProps}
 * @returns {JSX.Element}
 */
export const ErrorPanel: FC<ErrorPanelProps> = ({ errorMessage, refetchFunction }) => {
    const { t } = useTranslation()
    const navigate = useNavigate()
    const { colorMode } = useColorMode()

    const handleNavigate = (): void => {
        navigate('/')
    }
    return (
        <>
            <VStack>
                <Alert
                    status='error'
                    variant='subtle'
                    flexDirection='column'
                    textAlign='center'
                    rounded='2xl'
                >
                    <AlertIcon boxSize='4rem' mr={0} />
                    <AlertTitle mt={4} mb={1} fontSize='lg'>
                        {t('error-notification')}
                    </AlertTitle>
                    <AlertDescription>{errorMessage}</AlertDescription>
                </Alert>
                <HStack alignContent='center' justifyContent='center' spacing={3} mt='1rem'>
                    <Button
                        data-testid='refetch-button'
                        leftIcon={<RepeatIcon />}
                        onClick={refetchFunction}
                        border='1px'
                        borderColor={colorMode === 'light' ? 'gray.300' : 'gray.900'}
                    >
                        {t('try-again')}
                    </Button>
                    <Button
                        data-testid='search-another-topic-button'
                        leftIcon={<SearchIcon />}
                        onClick={handleNavigate}
                        border='1px'
                        borderColor={colorMode === 'light' ? 'gray.300' : 'gray.900'}
                    >
                        {t('search-another-topic')}
                    </Button>
                </HStack>
            </VStack>
        </>
    )
}
