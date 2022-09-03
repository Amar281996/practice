package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestTerraAscp(t *testing.T) {
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../TF-files",

		Vars: map[string]interface{}{
			"region": "us-east-2",
		},
	})
	/*defer terraform.Destroy(t, terraformOptions)*/
	terraform.InitAndApply(t, terraformOptions)

	output := terraform.Output(t, terraformOptions, "ASCP_installation")
	secret_arn := terraform.Output(t, terraformOptions, "secret_arn")
	assert.Equal(t, secret_arn, output)

	csi_output := terraform.Output(t, terraformOptions, "csi-driver")
	csi_driver_status := terraform.Output(t, terraformOptions, "csi_driver_status")
	assert.Equal(t, csi_driver_status, csi_output)

	pod_output := terraform.Output(t, terraformOptions, "pod_logs")
	pod_fileverification := terraform.Output(t, terraformOptions, "pod_file")
	assert.Equal(t, pod_fileverification, pod_output)
}
