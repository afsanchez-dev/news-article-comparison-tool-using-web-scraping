import { VStack } from '@chakra-ui/react'
import { type FC } from 'react'
import { ArticleDisplayer } from '.'
import { useAppSelector } from '../../app/hooks'
// import { BackButton } from '..'

/**
 * CompareArticles is a custom React component for managing article comparison
 * @returns {JSX.Element}
 */
export const CompareArticles: FC = () => {
    const layout = useAppSelector(state => state.compare.layout)
    return (
        <VStack spacing='1.75rem'>
            <ArticleDisplayer displayCount={layout} />
        </VStack>
    )
}
