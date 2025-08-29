import { LightningElement, track, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import configUpdate from "@salesforce/apex/CVTransformerApi.configUpdate";
import configUpsert from "@salesforce/apex/CVTransformerApi.configUpsert";
import contactCreate from "@salesforce/apex/CVTransformerApi.contactCreate";
import utilDataGet from "@salesforce/apex/CVTransformerApi.utilDataGet";

export default class CVTransformerUtility extends NavigationMixin(
  LightningElement
) {
  @track data = {};
  error;
  state = "loading";

  organization_id;

  @wire(utilDataGet)
  wiredData({ error, data }) {
    if (data) {
      this.data = data;
      this.error = null;
      this.state = this.data.organization_id ? "edit" : "setup";
    } else if (error) {
      this.data = {};
      this.error = error;
      this.state = "error";
    }
  }

  get isLoading() {
    return this.state === "loading";
  }

  get isEdit() {
    return this.state === "edit";
  }

  get isSetup() {
    return this.state === "setup";
  }

  get isConfigure() {
    return this.state === "configure";
  }

  get isError() {
    return this.state === "error";
  }

  onConfigure() {
    this.error = null;
    this.state = "configure";
  }

  onConfigureCancel() {
    this.error = null;
    this.state = "edit";
  }

  onSetup() {
    this.error = null;
    this.state = "setup";
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
      const organization_id = await configUpsert({ api_key: values.api_key });
      this.data = { ...this.data, organization_id };
      this.error = null;
      this.state = "edit";
    } catch (error) {
      this.data = {};
      this.error = error.body.message;
      this.state = "setup";
    }
  }

  get languageWithDefault() {
    return this.data.language || "en";
  }
  languageOptions = [
    { label: "English", value: "en" },
    { label: "Deutsch", value: "de" },
    { label: "Français", value: "fr" },
    { label: "Nederlands", value: "nl" }
  ];
  async onLanguageChange(event) {
    const language = event.detail.value;
    this.state = "loading";
    try {
      await configUpdate({ color_schema: this.data.color_schema, language });
      this.data = { ...this.data, language };
      this.error = null;
    } catch (error) {
      this.error = error.body.message;
    }
    this.state = "configure";
  }

  get colorSchemeWithDefault() {
    return this.data.color_scheme || "";
  }
  colorSchemeOptions = [
    { label: "System default", value: "" },
    { label: "Light", value: "light" },
    { label: "Dark", value: "dark" }
  ];
  async onColorSchemeChange(event) {
    const color_scheme = event.detail.value;
    this.state = "loading";
    try {
      await configUpdate({ color_scheme, language: this.data.language });
      this.data = { ...this.data, color_scheme };
      this.error = null;
    } catch (error) {
      this.error = error.body.message;
    }
    this.state = "configure";
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
        type: "standard__recordPage",
        attributes: {
          recordId: contact_id,
          actionName: "view"
        }
      });
      this.error = null;
    } catch (error) {
      this.error = error.body.message;
    }
    this.state = "edit";
  }
}
