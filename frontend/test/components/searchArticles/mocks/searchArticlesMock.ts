import type { ArticleSummary, SearchResult } from '../../../../src/types'
import nock from 'nock'
const baseUrl = process.env.SCRAPER_URL ?? ''

const errorResult = {
    scraper: 'el-pais',
    results: {
        error: {
            'el-pais': 'test error',
        },
    },
}

export function searchArticles(limit: number): SearchResult {
    const artSumms = []

    for (let index = 0; index < limit; index++) {
        artSumms.push({
            newspaper: 'Test Newspaper',
            authors: [
                {
                    name: 'Test Author' + index,
                    url: 'testAuthorUrl' + index,
                },
            ],
            title: 'Test title' + index,
            excerpt: 'This is a test excerpt' + index,
            date_time: '2023-10-30T15:31:48Z',
            url: 'testUrl1',
            is_premium: false,
        })
    }

    return [
        {
            scraper: 'el-pais',
            results: artSumms as ArticleSummary[],
        },
    ]
}

export const testTopic = 'testTopic'
const path = '/search_articles'
const baseServer = nock(baseUrl).get(/.*/)

const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST',
}

export const setupSuccess = (): void => {
    baseServer
        .reply(200, searchArticles(2), headers)
        .get(path)
        .query({
            topic: testTopic,
            page: 1,
            limit: 4,
        })
        .reply(200, searchArticles(3), headers)
}

export const setupTotalError = (): void => {
    baseServer.reply(200, [errorResult], headers)
}

export const setupDelayed = (): void => {
    baseServer.delay(200).reply(200, searchArticles(2), headers)
}

export const setupNetworkError = (): void => {
    baseServer.reply(400, { error: 'connection error' }, headers)
}
