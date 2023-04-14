import { logger } from './libs/logger';
import { HandlerInput, HandlerOutput } from './types/handler';

export const handler = async (
  event: HandlerInput
): Promise<HandlerOutput> => {
  logger.info('Event', { event });
  return {
    statusCode: 200,
    body: `Action ${event.action} instance completed successfully.`
  };
};