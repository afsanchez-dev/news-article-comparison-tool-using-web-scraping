import { type FC } from 'react'
import {
    Button,
    Card,
    CardFooter,
    CardHeader,
    Center,
    DrawerBody,
    DrawerFooter,
    Text,
    VStack,
    useColorMode,
} from '@chakra-ui/react'
import { CustomDrawer, addToCompare, selectCompareArticles } from '..'
import { useTranslation } from 'react-i18next'
import { useAppDispatch, useAppSelector } from '../../app/hooks'
import { selectCartItems } from '../articleCart'
import { parseDateTime } from '../../utils'
import { SearchIcon } from '@chakra-ui/icons'
import { useNavigate } from 'react-router-dom'
import type { ArticleSummary } from '../../types'

/**
 * Props for ArticleSelector
 */
export interface ArticleSelectorProps {
    /**
     * boolean for handling ArticleSelector opening
     */
    isOpen: boolean
    /**
     * function for handling ArticleSelector closing
     */
    onClose: () => void
}
/**
 * ArticleSelector is a custom React component for selecting articles for further comparison
 * @returns {JSX.Element}
 */
export const ArticleSelector: FC<ArticleSelectorProps> = ({ isOpen, onClose }) => {
    const { colorMode } = useColorMode()
    const { t } = useTranslation()
    const navigate = useNavigate()
    const selectedArticles = useAppSelector(state => selectCartItems(state))
    const comparedArticles = useAppSelector(state => selectCompareArticles(state))
    const dispatch = useAppDispatch()

    const handleNavigate = (): void => {
        navigate('/')
    }

    const handleArticleSelection = (artSumm: ArticleSummary): void => {
        onClose()
        dispatch(addToCompare(artSumm))
    }

    return (
        <CustomDrawer
            headerTitle={t('select-article')}
            isOpen={isOpen}
            onClose={onClose}
            placement={'right'}
        >
            <DrawerBody mt='1rem'>
                {selectedArticles.length >= 2 ? (
                    selectedArticles.map((artSumm, index) => {
                        const inComparison = comparedArticles.reduce<boolean>(
                            (acc, curr) => acc || curr.articleSummary.url === artSumm.url,
                            false
                        )
                        // If it's already in comparison, don't show
                        if (inComparison) return null
                        return (
                            <Card
                                key={index}
                                mb='1rem'
                                boxShadow='md'
                                bgColor={colorMode === 'light' ? 'gray.50' : 'blackAlpha.400'}
                                border={colorMode === 'light' ? '1px' : 'hidden'}
                                borderColor='gray.300'
                            >
                                <CardHeader>
                                    <Text fontSize='lg' fontWeight='bold'>
                                        {artSumm.title}
                                    </Text>
                                </CardHeader>
                                <CardFooter>
                                    <VStack align='left'>
                                        <Text fontSize='sm'>{artSumm.newspaper}</Text>
                                        <Text fontSize='sm'>
                                            {parseDateTime(artSumm.date_time)}
                                        </Text>
                                    </VStack>
                                </CardFooter>
                                <Button
                                    aria-label='select-article'
                                    m='1rem'
                                    size='sm'
                                    border={colorMode === 'light' ? '1px' : 'hidden'}
                                    borderColor='gray.300'
                                    onClick={() => {
                                        handleArticleSelection(artSumm)
                                    }}
                                >
                                    <Text>{t('select')}</Text>
                                </Button>
                            </Card>
                        )
                    })
                ) : (
                    <Center h='90%' textAlign='center'>
                        <VStack>
                            <Text fontWeight='medium' fontSize={'xl'} mb='2rem'>
                                {selectedArticles.length < 2 || selectedArticles.length > 0
                                    ? t('not-enough-articles')
                                    : t('no-articles-selected-yet')}
                            </Text>
                            <Button
                                data-testid='search-another-topic-button'
                                leftIcon={<SearchIcon />}
                                onClick={handleNavigate}
                            >
                                {t('search-articles')}
                            </Button>
                        </VStack>
                    </Center>
                )}
            </DrawerBody>
            <DrawerFooter justifyContent='center' borderTopWidth='thin' zIndex='2'>
                <Button
                    onClick={onClose}
                    border={colorMode === 'light' ? '1px' : 'hidden'}
                    borderColor='gray.300'
                >
                    {t('cancel')}{' '}
                </Button>
            </DrawerFooter>
        </CustomDrawer>
    )
}
