import { InstanceScheduler } from './instance-scheduler';
import { logger } from './libs/logger';
import { HandlerInput, HandlerOutput } from './types/handler';

export const handler = async (
  event: HandlerInput
): Promise<HandlerOutput> => {
  logger.info('Event', { event });
  const scheduler = new InstanceScheduler(
    event.schedule,
    event.action
  );
  await scheduler.run();
};