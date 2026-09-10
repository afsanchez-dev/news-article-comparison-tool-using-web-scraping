import type { FC } from 'react'
import {
    Alert,
    AlertDescription,
    AlertIcon,
    AlertTitle,
    CloseButton,
    VStack,
    useDisclosure,
    Text,
    Spacer,
    UnorderedList,
    ListItem,
} from '@chakra-ui/react'
import { useTranslation } from 'react-i18next'
import { type SearchArticlesErrorResult } from '../../types/scraper/searchArticlesResults'

/**
 * A function for transforming the scraper name
 * @param {string} scraperName
 * @returns {string}
 */
function getNewspaperName(scraperName: string): string {
    if (scraperName === 'el-pais') return 'El País'
    else if (scraperName === 'el-mundo') return 'El Mundo'
    else if (scraperName === 'la-voz-de-galicia') return 'La Voz De Galicia'
    return 'Unknown newspaper'
}

/**
 * Props for ScraperErrorAlert
 */
export interface ScraperErrorAlertProps {
    /**
     * A list of possible scraper errors
     */
    scraperErrors: SearchArticlesErrorResult[]
}

/**
 * ScraperErrorAlert is a custom React component for displaying minor search errors
 * such as a failure in just one of the scrapers but no errors in the rest
 * @param {ScraperErrorAlertProps}
 * @returns {JSX.Element}
 */
export const ScraperErrorAlert: FC<ScraperErrorAlertProps> = ({ scraperErrors }) => {
    const { isOpen: isVisible, onClose } = useDisclosure({ defaultIsOpen: true })

    const { t } = useTranslation()

    return isVisible ? (
        scraperErrors.length > 0 ? (
            <Alert status='warning'>
                <AlertIcon boxSize='1.75rem' />
                <Spacer />
                <VStack spacing='0.5rem' align='center' justify='center' textAlign='center'>
                    <AlertTitle>{t('no-results-scraper-error') + ': '}</AlertTitle>
                    <AlertDescription>
                        <UnorderedList>
                            {scraperErrors.map((scraperError, index) => {
                                return (
                                    <ListItem key={index} textAlign='left'>
                                        <Text>{getNewspaperName(scraperError.scraper)}</Text>
                                    </ListItem>
                                )
                            })}
                        </UnorderedList>
                    </AlertDescription>
                </VStack>
                <Spacer />
                <CloseButton
                    data-testid='scraper-alert-close-button'
                    alignSelf='flex-start'
                    position='relative'
                    right={-1}
                    top={-1}
                    onClick={onClose}
                />
            </Alert>
        ) : null
    ) : null
}
