import { HamburgerIcon } from '@chakra-ui/icons'
import { DrawerBody, IconButton, Spacer, useColorMode, useDisclosure } from '@chakra-ui/react'
import { CustomDrawer } from '.'
import { useTranslation } from 'react-i18next'

/**
 * SideBarDisplayer is a custom React component for displaying the application sidebar
 * @returns {JSX.Element}
 */
export const SideBarDisplayer = (): JSX.Element => {
    const { isOpen, onOpen, onClose } = useDisclosure()
    const { t } = useTranslation()
    const { colorMode } = useColorMode()

    return (
        <>
            <IconButton
                border={colorMode === 'light' ? '1px' : 'hidden'}
                borderColor='gray.300'
                aria-label='sidebar-button'
                data-testid='sidebar-button'
                icon={<HamburgerIcon />}
                onClick={onOpen}
                hidden={true}
            />
            <Spacer />
            <CustomDrawer
                headerTitle={t('menu')}
                isOpen={isOpen}
                onClose={onClose}
                placement={'left'}
            >
                <DrawerBody>this is a sidebar</DrawerBody>
            </CustomDrawer>
        </>
    )
}
