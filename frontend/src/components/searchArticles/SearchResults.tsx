import {
    Flex,
    Spacer,
    Button,
    Card,
    CardBody,
    CardFooter,
    CardHeader,
    HStack,
    Heading,
    Link,
    SimpleGrid,
    Spinner,
    Text,
    VStack,
    useColorMode,
    Tooltip,
    Checkbox,
} from '@chakra-ui/react'
import { type FC, useState, useEffect } from 'react'
import { useParams } from 'react-router-dom'
import { scraperApi } from '../../services'
import {
    ErrorType,
    type SearchResult,
    type SearchArticlesErrorResult,
    type SearchArticlesSuccessResult,
    type ArticleSummary,
} from '../../types'
import {
    ChevronDownIcon,
    ExternalLinkIcon,
    AddIcon,
    CloseIcon,
    NotAllowedIcon,
} from '@chakra-ui/icons'
import { useTranslation } from 'react-i18next'
import { getError, parseDateTime } from '../../utils'
import { ErrorPanel } from './ErrorPanel'
import { ScraperErrorAlert } from './ScraperErrorAlert'
import { addToCart, removeFromCart, selectCartItems } from '../articleCart'
import { useAppDispatch, useAppSelector } from '../../app/hooks'
import { clearCompare } from '..'

/**
 * SearchResults is a custom React component for displaying search results
 * @returns {JSX.Element}
 */
export const SearchResults: FC = () => {
    const { topic } = useParams()
    const dispatch = useAppDispatch()
    const selectArtSumms = useAppSelector(state => selectCartItems(state))
    const [searchArticles, { isLoading }] = scraperApi.endpoints.searchArticles.useLazyQuery({})
    const [moreIsLoading, setMoreIsLoading] = useState<boolean>(false)
    const [articleSumms, setArticleSumms] = useState<SearchArticlesSuccessResult[]>([])
    const [page, setPage] = useState<number>(0)
    const [scraperErrors, setScraperErrors] = useState<SearchArticlesErrorResult[]>([])
    const [errorMessage, setErrorMessage] = useState<string>('')
    const [showPremium, setShowPremium] = useState<boolean>(true)
    const { t } = useTranslation()
    const { colorMode } = useColorMode()

    // Checks if the scraper name is already in the scraperErrors
    const containsName = (
        scraperErrors: SearchArticlesErrorResult[],
        scraperError: SearchArticlesErrorResult
    ): boolean => {
        return scraperErrors.reduce<boolean>((acc, curr) => {
            return acc || curr.scraper === scraperError.scraper
        }, false)
    }
    const setData = (data: SearchResult): void => {
        // Filter the errors, checks no duplicates and sets them
        const errorResults = data.filter(searchResult => {
            return scraperErrors.length === 0
                ? 'error' in searchResult.results
                : 'error' in searchResult.results &&
                      !containsName(scraperErrors, searchResult as SearchArticlesErrorResult)
        }) as SearchArticlesErrorResult[]

        setScraperErrors([...scraperErrors, ...errorResults])

        // Filter the successful responses and sets them
        const successResults = data.filter(searchResult => {
            return Array.isArray(searchResult.results)
        }) as SearchArticlesSuccessResult[]

        setArticleSumms([...articleSumms, ...successResults])

        if (successResults.length === 0) setErrorMessage(t('empty-result-error') + ': ' + topic)
        else setErrorMessage('')
    }

    const handleSearchArticles = (): void => {
        if (topic != null) {
            searchArticles(
                {
                    topic,
                    page,
                    limit: 6,
                },
                true
            )
                .then(value => {
                    if (value.isSuccess) {
                        setData(value.data)
                    } else if (value.isError) {
                        setErrorMessage(t(getError(ErrorType.FetchError)))
                    }
                    setMoreIsLoading(false)
                })
                .catch((error: any) => {
                    console.error(error)
                    setMoreIsLoading(false)
                })
        }
    }

    const handleShowMore = (): void => {
        setMoreIsLoading(true)
        setPage(prevPage => prevPage + 1)
    }

    const existsArtSumm = (selectArticleSumm: ArticleSummary): boolean => {
        const artSumms = selectArtSumms
        return artSumms.reduce<boolean>(
            (acc, artSumm) => artSumm.url === selectArticleSumm.url || acc,
            false
        )
    }

    const handleSelectArticleSumm = (selectArticleSumm: ArticleSummary): void => {
        if (existsArtSumm(selectArticleSumm)) dispatch(removeFromCart(selectArticleSumm))
        else dispatch(addToCart(selectArticleSumm))
    }

    // For cleaning compared articles
    useEffect(() => {
        dispatch(clearCompare())
    }, [dispatch])

    // For managing requests
    useEffect(() => {
        handleSearchArticles()
    }, [page])

    return (
        <VStack ml='2rem' mr='2rem' mt='0.5rem' mb='1rem' spacing='1.75rem'>
            {isLoading ? (
                <Spinner data-testid='search-results-spinner' size='xl' />
            ) : errorMessage.length > 0 ? (
                <ErrorPanel errorMessage={errorMessage} refetchFunction={handleSearchArticles} />
            ) : (
                <>
                    <Flex
                        direction={{ base: 'column', sm: 'column', md: 'row' }}
                        align='center'
                        justify='center'
                        textAlign='center'
                    >
                        <Heading as='h1' fontSize={{ base: '1.5rem', md: '1.75rem' }}>
                            {t('results-for') + ': '}
                        </Heading>
                        <Spacer ml='1rem' />
                        <Text as='i' fontSize={{ base: '1.5rem', md: '1.75rem' }}>
                            {topic}
                        </Text>
                    </Flex>
                    <Checkbox
                        defaultChecked
                        onChange={e => {
                            setShowPremium(e.target.checked)
                        }}
                    >
                        {t('show-premium')}
                    </Checkbox>
                    <ScraperErrorAlert scraperErrors={scraperErrors} />
                    <SimpleGrid columns={{ sm: 1, md: 2, lg: 2, xl: 3 }} spacing='2rem'>
                        {articleSumms.map(articleResult => {
                            return articleResult.results.map((articleSumm, index) => {
                                if (articleSumm.is_premium && !showPremium) {
                                    return null
                                }
                                return (
                                    <Card
                                        key={index}
                                        boxShadow='lg'
                                        bgColor={
                                            colorMode === 'light' ? 'gray.50' : 'blackAlpha.400'
                                        }
                                        border={colorMode === 'light' ? '1px' : 'hidden'}
                                        borderColor='gray.300'
                                    >
                                        <CardHeader>
                                            <Link href={articleSumm.url} isExternal={true}>
                                                <HStack spacing='0.5rem'>
                                                    <Heading
                                                        as='h1'
                                                        fontSize={{
                                                            base: '1.5rem',
                                                            sm: '1.5rem',
                                                            md: '1.5rem',
                                                            lg: '1.75rem',
                                                        }}
                                                    >
                                                        {articleSumm.title}
                                                    </Heading>
                                                    <ExternalLinkIcon />
                                                </HStack>
                                            </Link>
                                        </CardHeader>
                                        <CardBody>
                                            <Text
                                                fontSize={{
                                                    sm: '1.25rem',
                                                    md: '1.25rem',
                                                    lg: '1.25rem',
                                                }}
                                            >
                                                {articleSumm.excerpt}
                                            </Text>
                                        </CardBody>
                                        <CardFooter>
                                            <VStack spacing='0.5rem' align='left'>
                                                {articleSumm.authors != null
                                                    ? articleSumm.authors.map((author, index) => {
                                                          return author.url != null ? (
                                                              <Link
                                                                  key={index}
                                                                  href={author.url}
                                                                  isExternal={true}
                                                              >
                                                                  <HStack spacing='0.5rem'>
                                                                      <Text key={index}>
                                                                          {author.name}
                                                                      </Text>
                                                                      <ExternalLinkIcon />
                                                                  </HStack>
                                                              </Link>
                                                          ) : (
                                                              <Text key={index}>{author.name}</Text>
                                                          )
                                                      })
                                                    : null}
                                                <Text>
                                                    {articleSumm.newspaper +
                                                        ' - ' +
                                                        parseDateTime(articleSumm.date_time)}
                                                </Text>
                                            </VStack>
                                        </CardFooter>

                                        <Tooltip
                                            label={
                                                articleSumm.is_premium ? t('is-premium-info') : null
                                            }
                                            aria-label='premium article notification'
                                        >
                                            <Button
                                                aria-label='add-article'
                                                m='1rem'
                                                onClick={() => {
                                                    handleSelectArticleSumm(articleSumm)
                                                }}
                                                isDisabled={articleSumm.is_premium}
                                                border={colorMode === 'light' ? '1px' : 'hidden'}
                                                borderColor='gray.300'
                                            >
                                                {articleSumm.is_premium ? (
                                                    <NotAllowedIcon />
                                                ) : existsArtSumm(articleSumm) ? (
                                                    <CloseIcon />
                                                ) : (
                                                    <AddIcon />
                                                )}
                                            </Button>
                                        </Tooltip>
                                    </Card>
                                )
                            })
                        })}
                    </SimpleGrid>
                    <Button
                        border={colorMode === 'light' ? '1px' : 'hidden'}
                        borderColor='gray.300'
                        isLoading={moreIsLoading}
                        onClick={handleShowMore}
                    >
                        <SimpleGrid columns={3} alignItems='center'>
                            <ChevronDownIcon />
                            <Text>{t('show-more')}</Text>
                        </SimpleGrid>
                    </Button>
                </>
            )}
        </VStack>
    )
}
