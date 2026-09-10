import {
    Drawer,
    DrawerCloseButton,
    DrawerContent,
    DrawerHeader,
    DrawerOverlay,
    useColorMode,
} from '@chakra-ui/react'
import type { FC, ReactNode } from 'react'

/**
 * Props for CustomDrawer
 */
export interface CustomDrawerProps {
    /**
     * Drawer title
     */
    headerTitle: string
    /**
     * Boolean for controlling opening
     */
    isOpen: boolean
    /**
     * Close function
     */
    onClose: () => void
    /**
     * Placement on the screen
     */
    placement: 'right' | 'left' | 'bottom' | 'top'
    /**
     * Contents of the drawer
     */
    children: ReactNode
}

/**
 * CustomDrawer is a custom React component that implements a collapsable menu
 * @param {DrawerProps}
 * @returns {JSX.Element}
 */
export const CustomDrawer: FC<CustomDrawerProps> = ({
    headerTitle,
    isOpen,
    onClose,
    placement,
    children,
}: CustomDrawerProps) => {
    const { colorMode } = useColorMode()
    return (
        <Drawer isOpen={isOpen} placement={placement} onClose={onClose} size='sm'>
            <DrawerOverlay />
            <DrawerContent bgColor={colorMode === 'light' ? 'white' : 'gray.900'}>
                <DrawerCloseButton />
                <DrawerHeader borderBottomWidth='thin'>{headerTitle}</DrawerHeader>
                {children}
            </DrawerContent>
        </Drawer>
    )
}
