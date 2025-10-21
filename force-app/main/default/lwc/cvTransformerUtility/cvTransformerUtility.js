import { LightningElement, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import configUpsert from "@salesforce/apex/CVTransformerApi.configUpsert";
import contactCreate from "@salesforce/apex/CVTransformerApi.contactCreate";
import organizationIdGet from "@salesforce/apex/CVTransformerApi.organizationIdGet";

export default class CVTransformerUtility extends NavigationMixin(
  LightningElement
) {
  organization_id;
  error;
  state = "loading";

  @wire(organizationIdGet)
  wiredData({ data, error }) {
    if (error) {
      this.organization_id = null;
      this.error = error;
      this.state = "error";
    } else {
      this.organization_id = data;
      this.error = null;
      this.state = data ? "edit" : "setup";
    }
  }

  get isLoading() {
    return this.state === "loading";
  }

  get isSetup() {
    return this.state === "setup";
  }

  onSetupCancel() {
    this.error = null;
    this.state = "edit";
  }

  async onSetupSubmit(event) {
    event.preventDefault();
    this.state = "loading";
    try {
      const inputs = [...this.template.querySelectorAll("lightning-input")];
      const values = Object.fromEntries(
        inputs.map((input) => [input.name, input.value])
      );
      this.organization_id = await configUpsert({ api_key: values.api_key });
      this.error = null;
      this.state = this.organization_id ? "edit" : "setup";
    } catch (error) {
      this.organization_id = null;
      this.error = error.body.message;
      this.state = "setup";
    }
  }

  get isEdit() {
    return this.state === "edit";
  }

  async onCvUpload(event) {
    const file = event.detail.files[0];
    if (!file) return;

    this.state = "loading";
    try {
      const contact_id = await contactCreate({
        content_document_id: file.documentId,
        content_version_id: file.contentVersionId
      });
      this[NavigationMixin.Navigate]({
        attributes: { actionName: "view", recordId: contact_id },
        type: "standard__recordPage"
      });
      this.error = null;
    } catch (error) {
      this.error = error.body.message;
    }
    this.state = "edit";
  }

  onApiKeyChange() {
    this.error = null;
    this.state = "setup";
  }
}
