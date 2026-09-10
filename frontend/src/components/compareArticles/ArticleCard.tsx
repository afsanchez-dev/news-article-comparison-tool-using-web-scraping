import { type FC } from 'react'
import { type ArticleSummary } from '../../types'
import { Card, CardHeader, useColorMode, Text, CardFooter, VStack } from '@chakra-ui/react'
import { parseDateTime } from '../../utils'

/**
 * ArticleCard props
 */
export interface ArticleCardProps {
    articleSummary: ArticleSummary
}

export const ArticleCard: FC<ArticleCardProps> = ({ articleSummary }) => {
    const { colorMode } = useColorMode()
    return (
        <Card
            mb='1rem'
            boxShadow='md'
            bgColor={colorMode === 'light' ? 'gray.50' : 'blackAlpha.400'}
            border={colorMode === 'light' ? '1px' : 'hidden'}
            borderColor='gray.300'
        >
            <CardHeader>
                <Text fontSize='lg' fontWeight='bold'>
                    {articleSummary.title}
                </Text>
            </CardHeader>
            <CardFooter>
                <VStack align='left'>
                    <Text fontSize='sm'>{articleSummary.newspaper}</Text>
                    <Text fontSize='sm'>{parseDateTime(articleSummary.date_time)}</Text>
                </VStack>
            </CardFooter>
        </Card>
    )
}
