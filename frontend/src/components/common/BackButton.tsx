import { ArrowBackIcon } from '@chakra-ui/icons'
import { IconButton } from '@chakra-ui/react'
import { type FC } from 'react'
import { useNavigate } from 'react-router-dom'

/**
 * Props for BackButton
 */
export interface BackButtonProps {
    /**
     * The route it navigates to
     */
    route: string
}

/**
 * BackButton is a custom React component for navigating back on the application
 * @returns {JSX.Element}
 */
export const BackButton: FC<BackButtonProps> = ({ route }) => {
    const navigate = useNavigate()
    const handleBackNavigation = (): void => {
        navigate(route)
    }
    return (
        <IconButton
            aria-label='back-button'
            icon={<ArrowBackIcon boxSize='1.5rem' />}
            size='lg'
            variant='ghost'
            rounded='full'
            onClick={handleBackNavigation}
        ></IconButton>
    )
}
