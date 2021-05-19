from aws_cdk import Stack
from constructs import Construct

from aws_cdk import (
    aws_autoscaling as autoscaling,
    aws_ec2 as ec2,
    aws_ecs as ecs,
    aws_ecs_patterns as ecs_patterns
)

class Eth2PirateshipStack(Stack):

    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        vpc = ec2.Vpc(self, "PirateVpc", max_azs=1)

        cluster = ecs.Cluster(self, "PirateCluster", container_insights=True, vpc=vpc)

        cluster.add_capacity(
                'Shipyard',
                block_devices=[
                    autoscaling.BlockDevice(
                        device_name='/dev/xvda',
                        volume=autoscaling.BlockDeviceVolume.ebs(volume_size=1000))  # 1 TB
                ],
                instance_type=ec2.InstanceType('m4.4xlarge'))
                

        task_definition = ecs.Ec2TaskDefinition(
                self, 'PirateTask',
                family='eth2',
                volumes=[
                    ecs.Volume(name='v', 
                               docker_volume_configuration=ecs.DockerVolumeConfiguration(
                                   driver='local',
                                   scope=ecs.Scope.SHARED,  # So it persists between beyond the lifetime of the task
                                   autoprovision=True))
                ])

        container = task_definition.add_container(
                'pirate',
                image=ecs.ContainerImage.from_registry('sigp/lighthouse'),  # TODO: configurable
                command=[
                    '--network pyrmont beacon',
                    '--http',
                    '--http-address 0.0.0.0'
                ],
                cpu=4 * 1024,  # 4vCPU -> 8-30GB memory
                container_name='Pirate',
                logging=ecs.LogDrivers.aws_logs(stream_prefix='pirate'),
                memory_reservation_mib=16 * 1024,  # 16GB
                port_mappings=[
                    ecs.PortMapping(container_port=9000, host_port=9000),  # protocol=TCP
                    ecs.PortMapping(container_port=5052, host_port=5052),  # protocol=TCP
                ],
                secrets={
                    # TODO: populate these with our keys
                },
                user='barbosa')

        service = ecs_patterns.ApplicationLoadBalancedEc2Service(
                self, "Pirateship",
#                certificate=???,  # TODO: set up the public domain
                cluster=cluster,
                desired_count=1,
#                domain_name='ethpirates.com',
#                domain_zone=???,  # TODO: set up the public domain
                public_load_balancer=True,
                task_definition=task_definition
                )

