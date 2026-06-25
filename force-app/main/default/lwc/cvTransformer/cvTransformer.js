import { RefreshEvent } from "lightning/refresh";
import { LightningElement, api } from "lwc";
import iframeTokenGet from "@salesforce/apex/CVTransformerApi.iframeTokenGet";
import locale from "@salesforce/i18n/lang";

export default class CVTransformer extends LightningElement {
  @api recordId;

  url = null;

  get isLoading() {
    return this.url === null;
  }

  connectedCallback() {
    iframeTokenGet().then((token) => {
      this.url = token
        ? "https://www.cv-transformer.com/salesforce/candidate?" +
          new URLSearchParams({ contact_id: this.recordId, locale, token })
        : "https://www.cv-transformer.com/salesforce/onboard?" +
          new URLSearchParams({ locale });
    });

    this.messageHandler = this.handleMessage.bind(this);
    window.addEventListener("message", this.messageHandler);
  }

  disconnectedCallback() {
    window.removeEventListener("message", this.messageHandler);
  }

  handleMessage(event) {
    if (
      event.origin !== "https://www.cv-transformer.com" ||
      event.data.type !== "cv-exported"
    )
      return;

    this.dispatchEvent(new RefreshEvent());
  }
}
