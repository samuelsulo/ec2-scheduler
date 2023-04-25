import { 
  StartInstancesCommand, 
  StopInstancesCommand,
  paginateDescribeInstances,
  EC2PaginationConfiguration,
  DescribeInstancesCommandInput,
  Instance,
  InstanceStateName,
} from '@aws-sdk/client-ec2';
import { ec2Client } from '../libs/ec2-client';
import { logger } from '../libs/logger';
import { Action } from '../types/handler';
import { FilteredInstance } from '../types/instance-scheduler';

export class InstanceScheduler {
  private instances: FilteredInstance[] = [];

  constructor(
    private readonly schedule: string,
    private readonly action: string
  ) {}

  async run(): Promise<void> {
    await this.listIntancesBySchedule();
    logger.info(
      `Found ${this.instances.length} instances with schedule ${this.schedule}`
    );

    if (this.instances.length === 0) {
      return;
    }

    if (this.action === Action.START) {
      await this.startInstances(this.getInstanceIds('stopped'));
      return;
    }
      
    if (this.action === Action.STOP) {
      await this.stopInstances(this.getInstanceIds('running'));
      return;
    }
      
    logger.info(`Unknown action ${this.action}`);
  }

  private async listIntancesBySchedule(): Promise<void> {
    const paginatorConfig: EC2PaginationConfiguration = {
      client: ec2Client,
      pageSize: 25
    };
    const commandInput: DescribeInstancesCommandInput = {
      Filters: [{ Name: 'tag:Schedule', Values: [this.schedule] }]
    };
    const paginator = paginateDescribeInstances(paginatorConfig, commandInput);
    
    for await (const page of paginator) {
      for (const reservation of page.Reservations || []) {
        if (reservation.Instances) {
          this.saveInstances(reservation.Instances);
        }
      }
    }
  }

  private async startInstances(instanceIds: string[]): Promise<void> {
    try {
      const command = new StartInstancesCommand({
        InstanceIds: instanceIds
      });
      const res = await ec2Client.send(command);
      logger.info('Started instances', {...res });
    } catch (error) {
      logger.error('Failed to start instances', { error });
    }
  }

  private async stopInstances(instanceIds: string[]): Promise<void> {
    try {
      const command = new StopInstancesCommand({
        InstanceIds: instanceIds
      });
      const res = await ec2Client.send(command);
      logger.info('Stopped instances', {...res });
    } catch (error) {
      logger.error('Failed to stop instances', { error });
    }
  }

  private saveInstances(instances: Instance[]): void {
    for (const instance of instances) {
      this.instances.push({ 
        instanceId: instance.InstanceId as string,
        state: instance.State?.Name as InstanceStateName
      });
    }
  }

  private getInstanceIds(stateName: InstanceStateName): string[] {
    const instancedIds: string[] = [];
    for (const instance of this.instances) {
      if (instance.state === stateName) {
        instancedIds.push(instance.instanceId);
      }
    }
    return instancedIds;
  }
}