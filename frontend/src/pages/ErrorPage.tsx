import type { FC } from 'react'
import { Center, Heading, Text, VStack } from '@chakra-ui/react'
import { useRouteError } from 'react-router-dom'
import type { routerError } from '../types'
import { useTranslation } from 'react-i18next'

/**
 * ErrorPage is a custom React component for displaying router errors
 * @returns {JSX.Element}
 */
export const ErrorPage: FC = () => {
    const error = useRouteError() as routerError
    const { t } = useTranslation()

    return (
        <Center h='100vh'>
            <VStack alignContent='center'>
                <Heading as='h1' fontWeight='bold'>
                    Ups!
                </Heading>
                <Text as='p'>{t('error-notification')}</Text>
                <Text as='i'>{error.statusText ?? error.message}</Text>
            </VStack>
        </Center>
    )
}
