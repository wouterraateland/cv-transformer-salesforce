import { LightningElement, api } from "lwc";
import iframeTokenGet from "@salesforce/apex/CVTransformerApi.iframeTokenGet";

export default class CVTransformer extends LightningElement {
  @api recordId;
  iframeUrl;

  get isLoading() {
    return !this.iframeUrl;
  }

  connectedCallback() {
    iframeTokenGet().then((token) => {
      this.iframeUrl =
        `https://www.cv-transformer.com/salesforce-candidate?` +
        new URLSearchParams({ contact_id: this.recordId, token });
    });
  }
}
