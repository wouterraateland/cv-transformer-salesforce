import { LightningElement, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import sendDataToApi from "@salesforce/apex/ExternalApiHandler.sendDataToApi";

export default class ContactActions extends LightningElement {
  @api recordId;

  handleApiCall() {
    sendDataToApi({ contactId: this.recordId })
      .then(() => {
        this.showToast("Success", "API triggered successfully", "success");
      })
      .catch((error) => {
        this.showToast("Error", error.body.message, "error");
      });
  }

  handleUploadFinished() {
    this.showToast("Success", "File uploaded successfully", "success");
  }

  showToast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }
}
