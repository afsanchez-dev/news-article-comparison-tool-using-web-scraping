import {
    Button,
    Card,
    CardBody,
    VStack,
    useDisclosure,
    Text,
    CardHeader,
    IconButton,
    Flex,
    SimpleGrid,
    Spacer,
    HStack,
    Spinner,
    useColorMode,
    Tooltip,
    SlideFade,
    Alert,
    AlertIcon,
    AlertDescription,
    Select,
} from '@chakra-ui/react'
import { useState, type FC, useEffect } from 'react'
import {
    ArticleSelector,
    type compareSelection,
    removeFromCompare,
    selectCompareArticles,
    setCurrSelector,
    ArticleBuilder,
    selectCurrSelection,
    clearCompare,
    updateLayout,
} from '.'
import { useAppDispatch, useAppSelector } from '../../app/hooks'
import { useTranslation } from 'react-i18next'
import { CloseIcon, RepeatIcon } from '@chakra-ui/icons'
import { scraperApi } from '../../services'
import type { Article, ArticleSummary } from '../../types'
import { ArticleErrorModal } from './ArticleErrorModal'
import { type successCompareResult } from '../../types/compareArticles/compareResults'

/**
 * ArticleDisplayer props
 */
export interface ArticleDisplayerProps {
    displayCount: number
}

/**
 * ArticleDisplayer is a custom React component for managing article comparison
 * @returns {JSX.Element}
 */
export const ArticleDisplayer: FC<ArticleDisplayerProps> = ({ displayCount }) => {
    const { isOpen, onOpen, onClose } = useDisclosure()
    const modalControls = useDisclosure()
    const { t } = useTranslation()
    const compareIndexes = new Array<number>(displayCount).fill(0).map((_, i) => i)
    const compareArticles = useAppSelector(state => selectCompareArticles(state))
    const currSelection = useAppSelector(state => selectCurrSelection(state))
    const dispatch = useAppDispatch()
    const [getArticle] = scraperApi.endpoints.getArticle.useLazyQuery({})
    const [isLoadingArticle, setIsLoadingArticle] = useState<ArticleLoading[]>([
        { index: 0, isLoading: false },
        { index: 1, isLoading: true },
    ])
    const [compareStatus, setCompareStatus] = useState<string>('')
    const [articlesCache, setArticlesCache] = useState<Article[]>([])
    const [articlesToCompare, setArticlesToCompare] = useState<ArticleToCompare[]>([])
    const [hasErrorUrl, setHasErrorUrl] = useState<boolean>(false)
    const { colorMode } = useColorMode()
    const [currSimilarity, setCurrSimilarity] = useState<number>(-1)
    const [hasSimilarityError, setHasSimilarityError] = useState<boolean>(false)
    const token = process.env.COMPARE_API_TOKEN ?? ''
    const layout = useAppSelector(state => state.compare.layout)

    interface ArticleToCompare {
        article: Article
        index: number
    }
    interface ArticleLoading {
        index: number
        isLoading: boolean
    }

    // Checks if it's in store
    const findCompareArt = (index: number): compareSelection | undefined => {
        return compareArticles.find(compareArticle => compareArticle.index === index)
    }
    const handlePreSelection = (index: number): void => {
        dispatch(setCurrSelector(index))
        onOpen()
    }
    const handleSwitchCompare = (): void => {
        const switched = articlesToCompare.map(art => {
            if (art.index === 0)
                return {
                    ...art,
                    index: 1,
                }
            else
                return {
                    ...art,
                    index: 0,
                }
        })

        setArticlesToCompare(switched)
    }
    const handleRemove = (index: number): void => {
        const filtered = articlesToCompare.filter(art => art.index !== index)
        setCurrSimilarity(-1)
        setArticlesToCompare(filtered)
        dispatch(removeFromCompare(index))
    }

    const updateToCompareArticles = (articleToCompare: ArticleToCompare): void => {
        if (articlesToCompare.length === 0) {
            setArticlesToCompare([...articlesToCompare, articleToCompare])
        } else {
            const filtered = articlesToCompare.filter(art => art.index !== articleToCompare.index)
            setArticlesToCompare([...filtered, articleToCompare])
        }
    }

    // Checks if it's in cache
    const findArticleInCache = (artSumm: ArticleSummary): Article | undefined => {
        return articlesCache.find(cachedArt => {
            return cachedArt.url === artSumm.url
        })
    }

    const updateIsLoadingArticle = (currSelection: compareSelection, state: boolean): void => {
        setIsLoadingArticle(
            isLoadingArticle.map(article => {
                if (article.index === currSelection.index)
                    return {
                        ...article,
                        isLoading: state,
                    }
                return article
            })
        )
    }

    const handleArticleSelection = (): void => {
        setHasErrorUrl(false)
        // setCurrSimilarity(-1)
        if (currSelection != null) {
            // Try find it in the article cache
            const cacheResult = findArticleInCache(currSelection.articleSummary)

            if (cacheResult != null) {
                updateToCompareArticles({
                    article: cacheResult,
                    index: currSelection.index,
                })

                return
            }
            updateIsLoadingArticle(currSelection, true)
            // If not in cache, make the request
            const url = encodeURIComponent(currSelection.articleSummary.url)
            getArticle({ url }, false)
                .then(value => {
                    if (value.isSuccess) {
                        setHasErrorUrl(false)
                        setArticlesCache([...articlesCache, value.data as Article])
                        updateToCompareArticles({
                            article: value.data as Article,
                            index: currSelection.index,
                        })
                        updateIsLoadingArticle(currSelection, false)
                    } else {
                        setHasErrorUrl(true)
                        updateIsLoadingArticle(currSelection, false)
                    }
                })
                .catch(e => {
                    console.log(e)
                    updateIsLoadingArticle(currSelection, false)
                })
        }
    }

    const extractTextFromArticle = (article: Article): string => {
        return article.body.reduce((acc, curr) => {
            return acc + Object.values(curr)[0]
        }, '')
    }
    const handleSimilarityCalc = (): void => {
        setCurrSimilarity(-1)
        setHasSimilarityError(false)
        setCompareStatus('loading')
        const text1 = extractTextFromArticle(articlesToCompare[0].article)
        const text2 = extractTextFromArticle(articlesToCompare[1].article)

        fetch('https://api.dandelion.eu/datatxt/sim/v1', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: new URLSearchParams({
                text1,
                text2,
                token,
                lang: 'es',
                bow: 'never',
            }),
        })
            .then(value => {
                if (value.ok) {
                    setHasSimilarityError(false)
                    value
                        .json()
                        .then(json => {
                            setCompareStatus('completed')
                            const data = json as successCompareResult
                            console.log(data)
                            const similarity = data.similarity * 100.0
                            setCurrSimilarity(similarity)
                        })
                        .catch(error => {
                            setHasSimilarityError(true)
                            setCompareStatus('failed')
                            console.log(error)
                        })
                } else {
                    setCompareStatus('failed')
                    setHasSimilarityError(true)
                }
            })
            .catch(error => {
                setHasSimilarityError(true)
                setCompareStatus('failed')
                console.log(error)
            })
    }

    const handleSelectChange = (event: React.FormEvent<HTMLSelectElement>): void => {
        const selectedValue = event.currentTarget.value
        if (selectedValue === '') return
        dispatch(updateLayout(parseInt(selectedValue)))
    }

    // For cleaning comparison selections
    useEffect(() => {
        dispatch(clearCompare())
        onClose()
        modalControls.onClose()
    }, [])

    // For handling new comparison selections
    useEffect(() => {
        if (compareArticles.length === 0) {
            setTimeout(() => {
                onOpen()
            }, 300)
        } else handleArticleSelection()
    }, [currSelection])

    // For displaying errors
    useEffect(() => {
        if (hasErrorUrl) {
            modalControls.onOpen()
        }
    }, [hasErrorUrl])

    return (
        <>
            <ArticleSelector isOpen={isOpen} onClose={onClose} />
            <ArticleErrorModal
                isOpen={modalControls.isOpen}
                onClose={modalControls.onClose}
                onRefetch={handleArticleSelection}
                onRemove={handleRemove}
            />
            <VStack maxW='90%' minW='90%'>
                <Flex
                    bgColor={colorMode === 'light' ? 'black' : 'blackAlpha.500'}
                    width='100%'
                    mb='1rem'
                    justify='space-evenly'
                    align='center'
                    roundedLeft='base'
                    roundedRight='base'
                    h='4rem'
                    border={colorMode === 'light' ? '1px' : 'hidden'}
                >
                    <Select
                        w='14rem'
                        bgColor={colorMode === 'light' ? 'gray.100' : 'whiteAlpha.200'}
                        color={colorMode === 'light' ? 'black' : 'white'}
                        ml={'2rem'}
                        onChange={handleSelectChange}
                        value={layout}
                    >
                        <option value={2}>
                            <Text>{t('comparison-view')}</Text>
                        </option>
                        <option value={1}>
                            <Text>{t('detail-view')}</Text>
                        </option>
                    </Select>
                    <Spacer />

                    <Button
                        onClick={handleSwitchCompare}
                        isDisabled={articlesToCompare.length !== 2}
                    >
                        <HStack spacing='0.5rem'>
                            <Text>{t('switch-articles')}</Text>
                            <RepeatIcon />
                        </HStack>
                    </Button>
                    <Spacer />

                    <Tooltip
                        label={
                            !(articlesToCompare.length === 2)
                                ? t('select-articles-to-compare-tooltip')
                                : null
                        }
                        aria-label='select-articles-to-compare-tooltip'
                    >
                        <Button
                            isDisabled={!(articlesToCompare.length === 2)}
                            mr='2rem'
                            onClick={handleSimilarityCalc}
                        >
                            {t('calculate-similarity') + ' (%)'}
                        </Button>
                    </Tooltip>
                </Flex>
                <SimpleGrid width='100%' columns={layout} spacing='1rem'>
                    {compareIndexes.map(index => {
                        return (
                            <Card
                                key={index}
                                boxShadow='lg'
                                border={colorMode === 'light' ? '1px' : 'hidden'}
                                bgColor={colorMode === 'light' ? 'gray.50' : 'blackAlpha.400'}
                                borderColor='gray.300'
                            >
                                {findCompareArt(index) == null ? null : (
                                    <CardHeader h='0.5rem' mb='0.5rem'>
                                        <Flex justify='right'>
                                            <IconButton
                                                icon={<CloseIcon />}
                                                onClick={() => {
                                                    handleRemove(index)
                                                }}
                                                size='xs'
                                                aria-label={'remove-compare-article'}
                                                variant='ghost'
                                            />
                                        </Flex>
                                    </CardHeader>
                                )}
                                <CardBody>
                                    {findCompareArt(index) == null ? (
                                        <VStack
                                            align='center'
                                            justify='center'
                                            h='50vh'
                                            textAlign='center'
                                        >
                                            <Text fontWeight='bold' fontSize='1.2rem' p='1rem'>
                                                {t('no-article-selected-yet')}
                                            </Text>
                                            <Button
                                                onClick={() => {
                                                    handlePreSelection(index)
                                                }}
                                                border={colorMode === 'light' ? '1px' : 'hidden'}
                                                borderColor='gray.300'
                                            >
                                                {t('select-article')}
                                            </Button>
                                        </VStack>
                                    ) : isLoadingArticle[index].isLoading ? (
                                        <Flex align='center' justify='center' h='40vh'>
                                            <Spinner size='xl' />
                                        </Flex>
                                    ) : (
                                        articlesToCompare.map(artToCompare => {
                                            if (artToCompare.index === index) {
                                                return (
                                                    <ArticleBuilder
                                                        article={artToCompare.article}
                                                        key={artToCompare.index}
                                                    />
                                                )
                                            } else return null
                                        })
                                    )}
                                </CardBody>
                            </Card>
                        )
                    })}
                </SimpleGrid>
                <Flex width='100%' justifyContent='center' mt='0.5rem'>
                    {compareStatus === 'loading' ? (
                        <Spinner size='xl' />
                    ) : currSimilarity >= 0 ? (
                        <HStack spacing='1rem'>
                            <Text fontSize='2rem' fontWeight='bold'>
                                {t('similarity') + ': '}
                            </Text>
                            <Text fontSize='2rem'>{currSimilarity.toFixed(2) + '%'}</Text>
                        </HStack>
                    ) : null}
                </Flex>
                <SlideFade in={hasSimilarityError}>
                    <Alert status='error' rounded='full' size={{ base: 'sm', md: 'md', lg: 'lg' }}>
                        <AlertIcon />
                        <AlertDescription>{t('comparison-error')}</AlertDescription>
                    </Alert>
                </SlideFade>
            </VStack>
        </>
    )
}
