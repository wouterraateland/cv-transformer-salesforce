import { LightningElement } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import contactCreate from "@salesforce/apex/CVTransformerApi.contactCreate";

export default class CVTransformerUtility extends NavigationMixin(
  LightningElement
) {
  error;
  state = "edit";

  get isLoading() {
    return this.state === "loading";
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
}
