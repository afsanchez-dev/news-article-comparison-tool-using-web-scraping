import {
    Button,
    Flex,
    HStack,
    IconButton,
    Modal,
    ModalBody,
    ModalContent,
    ModalFooter,
    ModalHeader,
    ModalOverlay,
    Text,
    useColorMode,
} from '@chakra-ui/react'
import { type FC } from 'react'
import { useTranslation } from 'react-i18next'
import { useAppDispatch, useAppSelector } from '../../app/hooks'
import { ArticleCard, selectCurrSelection } from '.'
import { removeFromCart } from '..'
import { CloseIcon, DeleteIcon, RepeatIcon } from '@chakra-ui/icons'

/**
 * ArticleErrorModal props
 */
export interface ArticleErrorModalProps {
    isOpen: boolean
    onClose: () => void
    onRefetch: () => void
    // Removes it from comparison panel and from the redux state
    onRemove: (index: number) => void
}

/**
 * ArticleErrorModal is a custom React component for managing article request errors
 * @returns {JSX.Element}
 */
export const ArticleErrorModal: FC<ArticleErrorModalProps> = ({
    isOpen,
    onClose,
    onRefetch,
    onRemove,
}) => {
    const { t } = useTranslation()
    const dispatch = useAppDispatch()
    const currSelection = useAppSelector(state => selectCurrSelection(state))
    const { colorMode } = useColorMode()

    const handleClose = (): void => {
        if (currSelection != null) {
            onRemove(currSelection.index)
            onClose()
        }
    }

    const handleRemove = (): void => {
        if (currSelection != null) {
            onRemove(currSelection.index)
            dispatch(removeFromCart(currSelection.articleSummary))
            onClose()
        }
    }

    const handleRefetch = (): void => {
        if (currSelection != null) {
            onRefetch()
            onClose()
        }
    }

    return (
        <Modal closeOnOverlayClick={false} isOpen={isOpen} onClose={onClose}>
            <ModalOverlay />
            <ModalContent>
                <Flex justify={'right'} mt='0.75rem' mr='0.75rem'>
                    <IconButton
                        variant='ghost'
                        icon={<CloseIcon />}
                        aria-label={'close-art-error-modal'}
                        size={'xs'}
                        onClick={handleClose}
                    />
                </Flex>
                <ModalHeader>{t('get-article-error')}</ModalHeader>
                <ModalBody>
                    {currSelection?.articleSummary != null ? (
                        <ArticleCard articleSummary={currSelection.articleSummary} />
                    ) : null}
                </ModalBody>
                <ModalFooter justifyContent='center'>
                    <HStack spacing='1rem'>
                        <Button
                            onClick={handleRefetch}
                            border='1px'
                            borderColor={colorMode === 'light' ? 'gray.300' : 'gray.900'}
                        >
                            <HStack spacing='1rem'>
                                <Text>{t('try-again')}</Text>
                                <RepeatIcon />
                            </HStack>
                        </Button>
                        <Button
                            onClick={handleRemove}
                            border='1px'
                            borderColor={colorMode === 'light' ? 'gray.300' : 'gray.900'}
                        >
                            <HStack spacing='1rem'>
                                <Text>{t('remove-this-article')}</Text>
                                <DeleteIcon />
                            </HStack>
                        </Button>
                    </HStack>
                </ModalFooter>
            </ModalContent>
        </Modal>
    )
}
