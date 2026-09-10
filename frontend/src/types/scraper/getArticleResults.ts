import type { Article, ApiError } from '.'

/**
 * Represents a getArticle query successful result
 * @type GetArticleSuccessResult
 */
export type GetArticleSuccessResult = Article

/**
 * Represents a getArticle query error result
 * @type GetArticleErrorResult
 */
export type GetArticleErrorResult = ApiError

/**
 * Represent a getArticle query result
 * @type GetArticleResult
 */
export type GetArticleResult = GetArticleSuccessResult | GetArticleErrorResult
