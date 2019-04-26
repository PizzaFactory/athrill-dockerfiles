
all:
	PRIVATE_REPO=camino.azurecr.io ./gen-azure-pipelines.sh > azure-pipelines.yml
