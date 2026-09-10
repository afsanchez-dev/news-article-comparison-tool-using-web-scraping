import {
    Button,
    HStack,
    Text,
    useDisclosure,
    DrawerBody,
    DrawerFooter,
    Card,
    CardHeader,
    CardFooter,
    VStack,
    Center,
    useColorMode,
    Flex,
} from '@chakra-ui/react'
import { CloseIcon, EditIcon } from '@chakra-ui/icons'
import { useTranslation } from 'react-i18next'
import { CustomDrawer, clearCart } from '..'
import { useAppDispatch, useAppSelector } from '../../app/hooks'
import { removeFromCart, selectCartItems } from '.'
import { type ArticleSummary } from '../../types'
import { parseDateTime } from '../../utils'
import { useNavigate } from 'react-router-dom'

/**
 * CartDisplayer is a custom React component for displaying cart contents
 * @returns {JSX.Element}
 */
export const CartDisplayer = (): JSX.Element => {
    const { isOpen, onOpen, onClose } = useDisclosure()
    const { colorMode } = useColorMode()
    const { t } = useTranslation()
    const selectedArticles = useAppSelector(state => selectCartItems(state))
    const dispatch = useAppDispatch()
    const navigate = useNavigate()

    const handleRemoveArticle = (artSumm: ArticleSummary): void => {
        dispatch(removeFromCart(artSumm))
    }

    const handleCompare = (): void => {
        onClose()
        navigate('/compare_articles/')
    }

    return (
        <>
            <Button
                onClick={onOpen}
                border={colorMode === 'light' ? '1px' : 'hidden'}
                borderColor='gray.300'
            >
                <HStack>
                    <Text>
                        {t('selected-articles') + ` (${selectedArticles.length.toString()})`}
                    </Text>
                    <EditIcon />
                </HStack>
            </Button>
            <CustomDrawer
                headerTitle={t('selected-articles')}
                isOpen={isOpen}
                onClose={onClose}
                placement={'right'}
            >
                <DrawerBody mt='1rem'>
                    {selectedArticles.length > 0 ? (
                        <Flex w='100%' justify='right' mb='1rem'>
                            <Button
                                border={colorMode === 'light' ? '1px' : 'hidden'}
                                borderColor='gray.300'
                                size='sm'
                                onClick={() => dispatch(clearCart())}
                            >
                                {t('clear-all')}
                            </Button>
                        </Flex>
                    ) : null}

                    {selectedArticles.length > 0 ? (
                        selectedArticles.map((artSumm, index) => {
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
                                        aria-label='remove-article'
                                        m='1rem'
                                        size='sm'
                                        border={colorMode === 'light' ? '1px' : 'hidden'}
                                        borderColor='gray.300'
                                        onClick={() => {
                                            handleRemoveArticle(artSumm)
                                        }}
                                    >
                                        <CloseIcon />
                                    </Button>
                                </Card>
                            )
                        })
                    ) : (
                        <Center h='90%' textAlign='center'>
                            <Text fontWeight='medium' fontSize={'xl'}>
                                {t('no-articles-selected-yet')}
                            </Text>
                        </Center>
                    )}
                </DrawerBody>
                <DrawerFooter justifyContent='center' borderTopWidth='thin' zIndex='2'>
                    <HStack spacing={'0.75rem'}>
                        <Button
                            onClick={onClose}
                            border={colorMode === 'light' ? '1px' : 'hidden'}
                            borderColor='gray.300'
                        >
                            {t('cancel')}
                        </Button>
                        <Button
                            border={colorMode === 'light' ? '1px' : 'hidden'}
                            borderColor='gray.300'
                            isDisabled={selectedArticles.length < 2}
                            onClick={handleCompare}
                        >
                            {t('compare')}
                        </Button>
                    </HStack>
                </DrawerFooter>
            </CustomDrawer>
        </>
    )
}
