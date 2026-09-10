import { Box, Flex, HStack, Heading, Link, Text, VStack } from '@chakra-ui/react'
import { type FC } from 'react'
import { type Article } from '../../types'
import { ExternalLinkIcon } from '@chakra-ui/icons'
import { parseDateTime } from '../../utils'
/**
 * Props for ComponentBuilder
 */
export interface ArticleBuilderProps {
    /**
     * The article body
     */
    article: Article
}
/**
 * ArticleBuilder is a custom React component for building articles
 * @returns {JSX.Element}
 */
export const ArticleBuilder: FC<ArticleBuilderProps> = ({ article }) => {
    return (
        <VStack textAlign='left' overflowY='auto' maxH='53vh' padding='1rem'>
            <Box as='section'>
                <Link href={article.url} isExternal={true}>
                    <HStack spacing='0.5rem'>
                        <Heading
                            as='h1'
                            fontSize={{
                                base: '1.75rem',
                                md: '2rem',
                            }}
                            mb='1rem'
                        >
                            {article.headline}
                        </Heading>
                        <ExternalLinkIcon />
                    </HStack>
                </Link>
                <Heading
                    as='h2'
                    fontSize={{
                        base: '1.2rem',
                        md: '1.5rem',
                    }}
                    fontWeight='medium'
                    mb='1rem'
                >
                    {article.subheadline}
                </Heading>
            </Box>
            <Flex as='section' textAlign='left' justifyItems='left' w='100%' direction='column'>
                {article.authors.map((author, index) => {
                    return author.url != null ? (
                        <Link key={index} href={author.url} isExternal={true}>
                            <HStack spacing='0.5rem'>
                                <Text key={index}>{author.name}</Text>
                                <ExternalLinkIcon />
                            </HStack>
                        </Link>
                    ) : (
                        <Text key={index}>{author.name}</Text>
                    )
                })}
                <Text>{article.newspaper + ' - ' + parseDateTime(article.last_date_time)}</Text>
            </Flex>
            <Box as='section' mt='1rem'>
                {article.body.map((item, index) => {
                    const tag = Object.keys(item)[0]
                    const content = item[tag]

                    switch (tag) {
                        case 'h2':
                            return (
                                <Heading
                                    as='h2'
                                    key={index}
                                    fontSize='1.4rem'
                                    mt='1rem'
                                    mb='1rem'
                                    fontWeight='semibold'
                                >
                                    {content}
                                </Heading>
                            )
                        case 'h3':
                            return (
                                <Heading
                                    as='h3'
                                    key={index}
                                    fontSize='1.4rem'
                                    mt='1rem'
                                    mb='1rem'
                                    fontWeight='medium'
                                >
                                    {content}
                                </Heading>
                            )

                        case 'p':
                            return (
                                <Text
                                    as='p'
                                    key={index}
                                    fontSize={{
                                        base: '1rem',
                                        md: '1.2rem',
                                    }}
                                    mb='1.5rem'
                                >
                                    {content}
                                </Text>
                            )

                        default:
                            return null
                    }
                })}
            </Box>
        </VStack>
    )
}
