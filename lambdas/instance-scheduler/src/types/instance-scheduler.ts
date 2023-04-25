import { InstanceStateName } from '@aws-sdk/client-ec2';

export type FilteredInstance = {
  instanceId: string;
  state: InstanceStateName;
}