export enum Action {
  OPEN = 'open',
  CLOSE = 'close'
}

export type HandlerInput = {
  action: Action;
};

export interface HandlerOutput {
  statusCode: number;
  body: string;
}