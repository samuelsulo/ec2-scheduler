export enum Action {
  START = 'start',
  STOP = 'stop'
}

export type HandlerInput = {
  schedule: string;
  action: Action;
};

export type HandlerOutput = void;