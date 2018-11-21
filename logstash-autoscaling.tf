# Service scaling alarms

resource "aws_cloudwatch_metric_alarm" "logstash-service_cpu_low" {
  alarm_name = "${var.logstash_conf["service"]}-service-cpuutilization-low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/ECS"
  period = "60"
  statistic = "Maximum"
  threshold = "25"

  dimensions {
    ClusterName = "${aws_ecs_cluster.logstash-cluster.name}"
    ServiceName = "${aws_ecs_service.logstash-ecs-service.name}"
  }

  alarm_actions = [
    "${aws_appautoscaling_policy.logstash-ecs-service-scale-down.arn}"]
}

resource "aws_cloudwatch_metric_alarm" "logstash-service_cpu_high" {
  alarm_name = "${var.logstash_conf["service"]}-service-cpuutilization-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/ECS"
  period = "60"
  statistic = "Maximum"
  threshold = "85"

  dimensions {
    ClusterName = "${aws_ecs_cluster.logstash-cluster.name}"
    ServiceName = "${aws_ecs_service.logstash-ecs-service.name}"
  }

  alarm_actions = [
    "${aws_appautoscaling_policy.logstash-ecs-service-scale-up.arn}"]
}

# Cluster scaling alarms

resource "aws_cloudwatch_metric_alarm" "logstash-cluster_cpu_low" {
  alarm_name = "${var.logstash_conf["service"]}-cluster-cpureservation-low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUReservation"
  namespace = "AWS/ECS"
  period = "60"
  statistic = "Maximum"
  threshold = "25"

  dimensions {
    ClusterName = "${aws_ecs_cluster.logstash-cluster.name}"
    ServiceName = "${aws_ecs_service.logstash-ecs-service.name}"
  }

  alarm_actions = ["${aws_autoscaling_policy.logstash-ecs-cluster-scale-down.arn}"]
}

resource "aws_cloudwatch_metric_alarm" "logstash-cluster_cpu_high" {
  alarm_name = "${var.logstash_conf["service"]}-cluster-cpureservation-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUReservation"
  namespace = "AWS/ECS"
  period = "60"
  statistic = "Maximum"
  threshold = "85"

  dimensions {
    ClusterName = "${aws_ecs_cluster.logstash-cluster.name}"
    ServiceName = "${aws_ecs_service.logstash-ecs-service.name}"
  }

  alarm_actions = ["${aws_autoscaling_policy.logstash-ecs-cluster-scale-up.arn}"]
}

# Service scaling:

resource "aws_appautoscaling_target" "logstash-ecs_target" {
  max_capacity = 4
  min_capacity = 1
  resource_id = "service/${var.logstash_conf["service"]}/${aws_ecs_service.logstash-ecs-service.name}"
  role_arn = "${aws_iam_role.autoscaling-role.arn}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace = "ecs"
}

resource "aws_appautoscaling_policy" "logstash-ecs-service-scale-up" {
  name = "${var.logstash_conf["service"]}-scale-up"
  service_namespace = "ecs"
  resource_id = "service/${var.logstash_conf["service"]}/${aws_ecs_service.logstash-ecs-service.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type = "ChangeInCapacity"
    cooldown = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment = 1
    }
  }
  depends_on = [
    "aws_appautoscaling_target.logstash-ecs_target"]
}

resource "aws_appautoscaling_policy" "logstash-ecs-service-scale-down" {
  name = "${var.logstash_conf["service"]}-scale-down"
  service_namespace = "ecs"
  resource_id = "service/${var.logstash_conf["service"]}/${aws_ecs_service.logstash-ecs-service.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type = "ChangeInCapacity"
    cooldown = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment = -1
    }
  }

  depends_on = [
    "aws_appautoscaling_target.logstash-ecs_target"]
}

# Cluster scaling

resource "aws_autoscaling_policy" "logstash-ecs-cluster-scale-up" {
  name = "${var.logstash_conf["service"]}-scale-up"
  autoscaling_group_name = "${aws_autoscaling_group.logstash-asg.name}"
  adjustment_type = "ChangeInCapacity"
  policy_type = "SimpleScaling"
  scaling_adjustment = 1
  cooldown = 60
}

resource "aws_autoscaling_policy" "logstash-ecs-cluster-scale-down" {
  name = "${var.logstash_conf["service"]}-scale-down"
  autoscaling_group_name = "${aws_autoscaling_group.logstash-asg.name}"
  adjustment_type = "ChangeInCapacity"
  policy_type = "SimpleScaling"
  scaling_adjustment = -1
  cooldown = 60
}
